import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class WeatherData {
  final String condition;
  final String suggestion;
  final IconData icon;
  final Color color;
  final double temperature;
  final String city;

  WeatherData({
    required this.condition,
    required this.suggestion,
    required this.icon,
    required this.color,
    required this.temperature,
    required this.city,
  });
}

class WeatherService {
  static const String _apiKey = '22866c776426d0a5b47cac7d8732afc7';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  static WeatherData? _cachedWeather;
  static DateTime? _cacheTimestamp;

  /// Returns a stream of weather updates.
  /// Emits whenever the location changes significantly (5km) or every hour.
  Stream<WeatherData> getWeatherStream() async* {
    // Initial fetch
    try {
      yield await getCurrentWeather().timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Initial stream fetch failed: $e');
      yield _cachedWeather ?? _getFallbackWeather();
    }

    // Movement-based updates (5km) - Medium accuracy for power optimization
    final movementStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5000,
      ),
    );

    // Periodic updates (1 hour)
    final timerStream = Stream.periodic(const Duration(hours: 1));

    await for (final event in _mergeStreams([movementStream, timerStream])) {
      try {
        if (event is Position) {
          debugPrint(
            'Stream Movement update: ${event.latitude}, ${event.longitude}',
          );
        }
        yield await getCurrentWeather(forceRefresh: true);
      } catch (_) {}
    }
  }

  Stream<dynamic> _mergeStreams(List<Stream> streams) {
    final controller = StreamController<dynamic>();
    List<StreamSubscription> subscriptions = [];

    controller.onListen = () {
      for (final stream in streams) {
        subscriptions.add(
          stream.listen(
            (data) => controller.add(data),
            onError: (e) => controller.addError(e),
            onDone: () {
              if (subscriptions.every((s) => s.isPaused)) {
                // Not perfect but helps
              }
            },
          ),
        );
      }
    };

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      subscriptions.clear();
    };

    return controller.stream;
  }

  Future<WeatherData> getCurrentWeather({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedWeather != null && _isCacheValid()) {
        return _cachedWeather!;
      }

      // Try for a fast response first
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && _cachedWeather == null) {
        debugPrint(
          'Last Known GPS Location: ${lastPosition.latitude}, ${lastPosition.longitude}',
        );
        // We can do a quick fetch with last known pos if we have no cache
        _fetchWithPosition(lastPosition)
            .then((data) {
              _cachedWeather = data;
              _cacheTimestamp = DateTime.now();
            })
            .catchError((_) {});
      }

      Position position = await _determinePosition().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Location fix took too long'),
      );

      return await _fetchWithPosition(position);
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return _cachedWeather ?? _getFallbackWeather();
    }
  }

  Future<WeatherData> _fetchWithPosition(Position position) async {
    String cityName = await _getCityName(
      position.latitude,
      position.longitude,
    ).timeout(const Duration(seconds: 3), onTimeout: () => 'Unknown');

    final response = await http
        .get(
          Uri.parse(
            '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric',
          ),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final parsed = _parseWeatherData(data, cityName);
      _cacheTimestamp = DateTime.now();
      _cachedWeather = parsed;
      return parsed;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<WeatherData> getWeatherByCity(String city) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data, city);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      debugPrint('Error fetching weather for city: $e');
      return _getFallbackWeather();
    }
  }

  Future<WeatherData> preloadTodayWeather() {
    return getCurrentWeather(forceRefresh: true);
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Accuracy optimized for Bloom
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    debugPrint(
      'Current GPS Location: ${position.latitude}, ${position.longitude}',
    );
    return position;
  }

  /// Gets city name from coordinates
  Future<String> _getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first.locality ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      debugPrint('Error getting city name: $e');
      return 'Unknown';
    }
  }

  /// Parses weather data from API response
  WeatherData _parseWeatherData(Map<String, dynamic> data, String city) {
    final weatherMain = data['weather'][0]['main'].toString().toLowerCase();
    final temp = data['main']['temp'].toDouble();

    String condition;
    String suggestion;
    IconData icon;
    Color color;

    switch (weatherMain) {
      case 'clear':
        condition = 'Clear';
        suggestion = 'Perfect time for a walk or outdoor meditation!';
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case 'clouds':
        condition = 'Cloudy';
        suggestion = 'Good time for some deep breathing exercises.';
        icon = Icons.cloud;
        color = Colors.grey;
        break;
      case 'rain':
      case 'drizzle':
        condition = 'Rainy';
        suggestion = 'Perfect for cozy journaling indoors.';
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case 'thunderstorm':
        condition = 'Stormy';
        suggestion = 'Stay safe inside and practice mindfulness.';
        icon = Icons.thunderstorm;
        color = Colors.deepPurple;
        break;
      case 'snow':
        condition = 'Snowy';
        suggestion = 'Enjoy the peaceful scenery and stay warm!';
        icon = Icons.ac_unit;
        color = Colors.lightBlue;
        break;
      case 'mist':
      case 'fog':
      case 'haze':
        condition = 'Misty';
        suggestion = 'Great atmosphere for reflection and calm.';
        icon = Icons.cloud_queue;
        color = Colors.blueGrey;
        break;
      default:
        condition = 'Clear';
        suggestion = 'Have a wonderful day!';
        icon = Icons.wb_sunny;
        color = Colors.orange;
    }

    return WeatherData(
      condition: condition,
      suggestion: suggestion,
      icon: icon,
      color: color,
      temperature: temp,
      city: city,
    );
  }

  bool _isCacheValid() {
    if (_cacheTimestamp == null || _cachedWeather == null) return false;
    // Valid for 30 minutes in the same session
    return DateTime.now().difference(_cacheTimestamp!).inMinutes < 30;
  }

  /// Returns fallback weather data when API fails
  WeatherData _getFallbackWeather() {
    return WeatherData(
      condition: 'Clear',
      suggestion: 'Have a wonderful day!',
      icon: Icons.wb_sunny,
      color: Colors.orange,
      temperature: 22.0,
      city: 'Your Location',
    );
  }
}
