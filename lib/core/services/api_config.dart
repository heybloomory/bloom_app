import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class ApiConfig {
  static String get baseUrl {
    // Web (browser)
  if (kIsWeb) return 'http://localhost:4000';
          return 'http://localhost:4000';


    // Android emulator -> host machine
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }

    // iOS simulator / desktop
    return 'http://localhost:4000';
  }
}
