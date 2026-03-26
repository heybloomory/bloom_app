import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/services/api_config.dart';

class AuthService {
  AuthService._();

  static const _tokenKey = 'bloom_api_jwt_secure';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> logout() async {
    await deleteToken();
  }

  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) return true;
      final exp = data['exp'];
      if (exp is! int) return true;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp <= now;
    } catch (_) {
      return true;
    }
  }

  /// Validate session with backend, clearing token on invalid/expired session.
  static Future<bool> validateSession() async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) return false;
    if (isTokenExpired(token)) {
      await deleteToken();
      return false;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uris = <Uri>[
      Uri.parse('${ApiConfig.baseUrl}/api/auth/me'),
      Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
    ];

    for (final uri in uris) {
      try {
        final res = await http.get(uri, headers: headers);
        if (res.statusCode == 200) return true;
      } catch (_) {}
    }

    await deleteToken();
    return false;
  }
}
