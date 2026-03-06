import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class AuthApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Register a new user (email/password or phone/password) against Bloomory Node/Mongo API.
  /// Returns JWT token and persists it locally.
  static Future<String> register({
    required String password,
    String? name,
    String? email,
    String? phone,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': (name ?? '').trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'password': password.trim(),
      }),
    );

    final Map<String, dynamic> data = _safeJson(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Registration succeeded but token was missing.');
      }
      await AuthSession.setToken(token);
      return token;
    }

    final msg = (data['message'] ?? 'Registration failed').toString();
    throw Exception(msg);
  }

  /// Email/password login against Bloomory Node/Mongo API.
  /// Returns JWT token. Also persists it locally.
  static Future<String> loginWithEmail(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login-email');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final Map<String, dynamic> data = _safeJson(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final token = (data['token'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Login succeeded but token was missing.');
      }
      await AuthSession.setToken(token);
      return token;
    }

    final msg = (data['message'] ?? 'Email login failed').toString();
    throw Exception(msg);
  }

  /// Optional: after Firebase Google sign-in, you can call this to sync/login
  /// on Bloomory backend. Your backend must implement this route.
  ///
  /// If the backend route is not implemented yet, we simply return null and
  /// allow the app to continue using Firebase session for UI access.
  static Future<String?> loginWithGoogleIdToken(String idToken) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login-google');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final Map<String, dynamic> data = _safeJson(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = (data['token'] ?? '').toString();
        if (token.isNotEmpty) {
          await AuthSession.setToken(token);
          return token;
        }
      }

      // If backend returns 404 or non-success, just treat as not supported.
      return null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }
}
