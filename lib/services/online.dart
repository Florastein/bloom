import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// Returns true if the device is connected to the internet
Future<bool> isInternetAvailable() async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult == ConnectivityResult.none) {
    // Not connected to Wi-Fi or mobile
    return false;
  }

  try {
    final result = await http.get(Uri.parse('https://www.google.com')).timeout(
      const Duration(seconds: 5),
    );

    if (result.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (_) {
    return false;
  }
}
