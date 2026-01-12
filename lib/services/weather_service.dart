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
  static DateTime? _cacheDay;

  Future<WeatherData> getCurrentWeather({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedWeather != null && _isCacheValid()) {
        return _cachedWeather!;
      }

      Position position = await _determinePosition();

      String cityName = await _getCityName(
        position.latitude,
        position.longitude,
      );

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
        _cacheDay = _todayKey();
        _cachedWeather = parsed;
        return parsed;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return _getFallbackWeather();
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

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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
    if (_cacheDay == null || _cachedWeather == null) return false;
    return _cacheDay == _todayKey();
  }

  DateTime _todayKey() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
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
