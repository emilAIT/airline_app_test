import 'dart:io';

class Config {
  // Dynamic base URL that works on any machine
  static String get baseUrl {
    // Check for environment variable first
    final envUrl = Platform.environment['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }

    if (Platform.isAndroid) {
      // For Android emulator, use the special IP
      return 'http://10.246.137.141:8000/api/v1';
      // For physical Android device, the app will need to be configured
      // or use a discovery service
    }
    
    // For iOS simulator, web, and desktop
    return 'http://127.0.0.1:8000/api/v1';
  }
}
