import 'dart:convert';
import 'package:http/http.dart' as http;

/// Caches a single inspiration for the current day to avoid repeated calls.
class InspirationService {
  static const String _apiKey = 'YOUR_INSPIRATION_API_KEY';
  static const String _baseUrl = 'https://example.com/api/inspiration';

  static String? _cachedQuote;
  static DateTime? _cachedDay;
  static String? _cachedCondition;

  // Local quote pools
  static const List<String> _generalQuotes = [
    "Believe you can and you're halfway there.",
    "The only way to do great work is to love what you do.",
    "You are enough just as you are.",
    "Every day is a fresh start.",
    "Keep your face always toward the sunshine—and shadows will fall behind you.",
    "Small steps every day add up to big results.",
    "Your potential is endless.",
  ];

  static const Map<String, List<String>> _weatherQuotes = {
    'clear': [
      "Sunshine is a reminder to shine from within.",
      "Let today's light recharge your spirit.",
      "Clear skies, clear mind—take a deep breath and own the day.",
    ],
    'cloudy': [
      "Even on cloudy days, your light matters.",
      "Gentle skies invite gentle self-compassion.",
      "Clouds pass—your calm stays.",
    ],
    'rainy': [
      "Rain feeds growth—let it nourish your patience.",
      "Cozy moments are perfect for reflection.",
      "Like rain, feelings flow and clear the air.",
    ],
    'stormy': [
      "Strong roots hold through any storm.",
      "Pause, breathe, and let the thunder roll past.",
      "You are safe in your calm harbor.",
    ],
    'snowy': [
      "Quiet snow, quiet mind—find softness today.",
      "Let the stillness be your reset button.",
      "Warmth can be chosen—wrap yourself in kindness.",
    ],
    'misty': [
      "It's okay to move slowly when the path is soft.",
      "Even in fog, your next step is enough.",
      "Gentle focus beats force when things feel hazy.",
    ],
    'default': [
      "You don't have to rush to make real progress.",
      "Your pace is perfect for you.",
      "Small, steady steps change everything.",
    ],
  };

  static const Map<int, List<String>> _dayQuotes = {
    1: ["New week, new chance to be kind to yourself."],
    2: ["Tuesday is for tiny wins—collect one now."],
    3: ["Midweek check-in: what's one thing you're proud of?"],
    4: ["You're closer than you think—keep a gentle pace."],
    5: ["Friday is for finishing with grace, not force."],
    6: ["Saturday is for rest that refuels, not just distracts."],
    7: ["A calm Sunday sets the tone for the week ahead."],
  };

  String selectLocalQuote({String? condition, int? dayOfWeek}) {
    final conditionKey = (condition ?? 'default').toLowerCase();
    final dayKey = dayOfWeek ?? DateTime.now().weekday;

    final List<String> options = [];
    if (_weatherQuotes.containsKey(conditionKey)) {
      options.addAll(_weatherQuotes[conditionKey]!);
    }
    if (_dayQuotes.containsKey(dayKey)) {
      options.addAll(_dayQuotes[dayKey]!);
    }
    options.addAll(_generalQuotes);

    if (options.isEmpty) {
      return "You are enough just as you are.";
    }

    return options[DateTime.now().millisecond % options.length];
  }

  Future<String?> getDailyInspiration({
    required String? condition,
    required int dayOfWeek,
    required String fallback,
  }) async {
    if (_cachedQuote != null && _isCacheValid(condition)) {
      return _cachedQuote;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'condition': (condition ?? 'default').toLowerCase(),
          'day': dayOfWeek.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $_apiKey'},
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final quote = _extractQuote(body);
        if (quote != null && quote.isNotEmpty) {
          _cacheQuote(quote, condition);
          return quote;
        }
      }
    } catch (_) {
      // Swallow errors and fall back
    }

    return fallback;
  }

  String? _extractQuote(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['quote'] is String) return body['quote'] as String;
      if (body['data'] is Map && body['data']['quote'] is String) {
        return body['data']['quote'] as String;
      }
      if (body['results'] is List && body['results'].isNotEmpty) {
        final first = body['results'].first;
        if (first is Map && first['quote'] is String) {
          return first['quote'] as String;
        }
      }
    }
    if (body is List && body.isNotEmpty) {
      final first = body.first;
      if (first is Map && first['quote'] is String) {
        return first['quote'] as String;
      }
      if (first is String) return first;
    }
    return null;
  }

  bool _isCacheValid(String? condition) {
    if (_cachedQuote == null || _cachedDay == null) return false;
    final today = _todayKey();
    return _cachedDay == today && _cachedCondition == (condition ?? 'default');
  }

  void _cacheQuote(String quote, String? condition) {
    _cachedQuote = quote;
    _cachedCondition = condition ?? 'default';
    _cachedDay = _todayKey();
  }

  DateTime _todayKey() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day);
  }
}
