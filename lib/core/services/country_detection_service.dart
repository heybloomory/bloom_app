import 'dart:ui' as ui;

import 'package:http/http.dart' as http;

/// Country detection used by auth screens.
///
/// Priority:
/// 1) IP geolocation (more accurate for travel / roaming devices)
/// 2) Device locale country code
/// 3) Fallback to non-India
class CountryDetectionService {
  CountryDetectionService._();

  static const String _indiaCode = 'IN';

  static Future<String?> detectCountryCode() async {
    final ipCode = await _detectFromIp();
    if (ipCode != null && ipCode.isNotEmpty) return ipCode;

    final localeCode = ui.PlatformDispatcher.instance.locale.countryCode;
    if (localeCode != null && localeCode.trim().isNotEmpty) {
      return localeCode.toUpperCase();
    }
    return null;
  }

  static Future<bool> isIndia() async {
    final code = await detectCountryCode();
    return (code ?? '').toUpperCase() == _indiaCode;
  }

  static Future<String?> _detectFromIp() async {
    try {
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final body = response.body;
      final match = RegExp('"country_code"\\s*:\\s*"([A-Za-z]{2})"')
          .firstMatch(body);
      if (match == null) return null;
      return match.group(1)?.toUpperCase();
    } catch (_) {
      return null;
    }
  }
}
