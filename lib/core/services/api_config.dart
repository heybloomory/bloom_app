import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Central place for configuring the Bloomory backend base URL.
///
/// - Web / iOS / desktop simulator: http://localhost:4001
/// - Android emulator: http://10.0.2.2:4001 (host loopback)
class ApiConfig {
  static String get baseUrl {
    // Web (Flutter Web runs in the browser on the host machine)
    if (kIsWeb) {
      return 'http://localhost:4001';
    }

    // Android emulator -> API on host machine
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4001';
    }

    // iOS simulator / desktop
    return 'http://localhost:4001';
  }
}
