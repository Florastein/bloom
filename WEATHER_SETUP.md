# Weather API Setup Instructions

## Getting Your OpenWeatherMap API Key

1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Click "Sign Up" and create a free account
3. After signing up, go to "API keys" section
4. Copy your API key
5. Open `lib/services/weather_service.dart`
6. Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String _apiKey = 'your_actual_api_key_here';
   ```

## Features

The weather service now provides:
- Real-time weather data based on user's location
- Current temperature in Celsius
- Weather conditions (Clear, Cloudy, Rainy, etc.)
- City name detection
- Personalized mood suggestions based on weather
- Automatic fallback to default data if API fails

## Permissions

The app automatically requests location permissions:
- **Android**: ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION
- **iOS**: NSLocationWhenInUseUsageDescription

## Notes

- The free tier of OpenWeatherMap allows 60 calls/minute and 1,000,000 calls/month
- Location permissions are required for automatic weather detection
- If permissions are denied, the app falls back to default weather data
- Weather data is fetched when the dashboard loads
