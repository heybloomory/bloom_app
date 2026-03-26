import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class AuthApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  /// Backend-driven auth decision.
  /// `loginType` should be `mobile` or `email`.
  /// `isRegistered` indicates whether user already exists.
  /// `country` is backend source of truth.
  static Future<AuthRoutingDecision> detectUser(String input) async {
    final clean = input.trim();
    final payload = {
      ...(_looksLikeEmail(clean)
          ? <String, dynamic>{'email': clean}
          : <String, dynamic>{'mobile': clean}),
      'input': clean,
    };

    final data = await _postSuccessData(
      endpoints: const [
        '/api/auth/detect-user',
        '/api/auth/detect',
        '/api/auth/login-routing',
      ],
      payload: payload,
      fallbackMessage: 'Could not detect login method',
    );
    return AuthRoutingDecision.fromJson(data, fallbackInput: clean);
  }

  /// Send OTP to the provided phone number.
  ///
  /// Backend endpoint: POST /api/auth/send-otp
  /// Body: { mobile }
  /// Returns: { success: true, message: "...", otp?: "..." } (otp only in dev)
  static Future<void> sendOtp(String mobile) async {
    final uri = Uri.parse('$_baseUrl/api/auth/send-otp');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    final Map<String, dynamic> data = _safeJson(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    final msg = (data['message'] ?? 'OTP send failed').toString();
    throw Exception(msg);
  }

  /// Send OTP to email (global flow).
  static Future<void> sendEmailOtp(String email) async {
    final payload = {'email': email.trim()};
    await _postSuccess(
      endpoints: const [
        '/api/auth/send-email-otp',
        '/api/auth/send-otp-email',
        '/api/auth/send-otp',
      ],
      payload: payload,
      fallbackMessage: 'Email OTP send failed',
    );
  }

  /// Unified OTP sender for country-based login.
  static Future<void> sendLoginOtp({
    required bool isIndia,
    required String identifier,
  }) async {
    if (isIndia) {
      await sendOtp(identifier);
      return;
    }
    await sendEmailOtp(identifier);
  }

  /// Verify OTP and persist backend JWT if returned.
  ///
  /// Supports both phone and email payload keys depending on region.
  static Future<String> verifyLoginOtp({
    required bool isIndia,
    required String identifier,
    required String otp,
  }) async {
    final payload = <String, dynamic>{
      ...(isIndia
          ? <String, dynamic>{'phone': identifier.trim()}
          : <String, dynamic>{'email': identifier.trim()}),
      'otp': otp.trim(),
    };
    final data = await _postSuccessData(
      endpoints: isIndia
          ? const [
              '/api/auth/verify-otp',
              '/api/auth/verify-login-otp',
              '/api/auth/login-otp',
            ]
          : const [
              '/api/auth/verify-email-otp',
              '/api/auth/verify-otp',
              '/api/auth/verify-login-otp',
            ],
      payload: payload,
      fallbackMessage: 'OTP verification failed',
    );

    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw Exception('OTP verified but token was missing.');
    }
    await AuthSession.setToken(token);
    return token;
  }

  /// Single method to complete OTP auth:
  /// - verify existing user
  /// - if user is not registered, auto-register using OTP and persist token
  static Future<String> completeOtpAuth({
    required AuthRoutingDecision decision,
    required String otp,
  }) async {
    try {
      return await verifyLoginOtp(
        isIndia: decision.isIndia,
        identifier: decision.identifier,
        otp: otp,
      );
    } catch (e) {
      if (decision.isRegistered) rethrow;
      final token = await _autoRegisterWithOtp(
        isIndia: decision.isIndia,
        identifier: decision.identifier,
        otp: otp,
      );
      if (token == null || token.isEmpty) {
        rethrow;
      }
      await AuthSession.setToken(token);
      return token;
    }
  }

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

  static bool _looksLikeEmail(String value) => value.contains('@');

  static Future<String?> _autoRegisterWithOtp({
    required bool isIndia,
    required String identifier,
    required String otp,
  }) async {
    final payload = {
      ...(isIndia
          ? <String, dynamic>{'mobile': identifier.trim()}
          : <String, dynamic>{'email': identifier.trim()}),
      'otp': otp.trim(),
    };

    final data = await _postSuccessData(
      endpoints: const [
        '/api/auth/register-otp',
        '/api/auth/auto-register',
        '/api/auth/signup-otp',
      ],
      payload: payload,
      fallbackMessage: 'Auto registration failed',
    );

    final token = (data['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }

  static Future<void> _postSuccess({
    required List<String> endpoints,
    required Map<String, dynamic> payload,
    required String fallbackMessage,
  }) async {
    await _postSuccessData(
      endpoints: endpoints,
      payload: payload,
      fallbackMessage: fallbackMessage,
    );
  }

  static Future<Map<String, dynamic>> _postSuccessData({
    required List<String> endpoints,
    required Map<String, dynamic> payload,
    required String fallbackMessage,
  }) async {
    Exception? lastError;

    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse('$_baseUrl$endpoint');
        final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
        final data = _safeJson(response.body);
        if ((response.statusCode == 200 || response.statusCode == 201) &&
            data['success'] == true) {
          return data;
        }
        if (response.statusCode == 404 || response.statusCode == 405) {
          continue;
        }
        final msg = (data['message'] ?? fallbackMessage).toString();
        lastError = Exception(msg);
      } catch (e) {
        lastError = Exception(e.toString());
      }
    }

    throw lastError ?? Exception(fallbackMessage);
  }
}

class AuthRoutingDecision {
  final String country;
  final String loginType; // mobile | email
  final bool isRegistered;
  final String identifier;

  const AuthRoutingDecision({
    required this.country,
    required this.loginType,
    required this.isRegistered,
    required this.identifier,
  });

  bool get isIndia => country.toUpperCase() == 'IN';
  bool get useMobileOtp => loginType.toLowerCase() == 'mobile';

  static AuthRoutingDecision fromJson(
    Map<String, dynamic> json, {
    required String fallbackInput,
  }) {
    final country = (json['country'] ?? '').toString().toUpperCase();
    final loginType = (json['loginType'] ?? '').toString().toLowerCase();
    final isRegistered = json['isRegistered'] == true;

    final fallbackType = fallbackInput.contains('@') ? 'email' : 'mobile';
    return AuthRoutingDecision(
      country: country.isEmpty ? 'UNKNOWN' : country,
      loginType: (loginType == 'mobile' || loginType == 'email')
          ? loginType
          : fallbackType,
      isRegistered: isRegistered,
      identifier: fallbackInput.trim(),
    );
  }
}
