import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

/// Lightweight HTTP client that automatically attaches the Bloomory JWT
/// and provides Axios-style retry behavior for GET requests.
class ApiClient {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    int retries = 3,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = await _authHeaders();

    final response = await _withRetry(
      () => http.get(uri, headers: headers),
      retries: retries,
    );

    _throwForAuth(response);
    return _decodeJson(response);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthSession.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static void _throwForAuth(http.Response response) {
    if (response.statusCode == 401) {
      throw Exception('Unauthorized (401) – please log in again.');
    }
  }

  static Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Axios-style retry wrapper with exponential backoff + jitter.
  ///
  /// Retries on:
  /// - network errors (SocketException, TimeoutException),
  /// - 5xx responses,
  /// - 429 (Too Many Requests).
  static Future<http.Response> _withRetry(
    Future<http.Response> Function() send, {
    int retries = 3,
    Duration baseDelay = const Duration(milliseconds: 300),
    Duration maxDelay = const Duration(seconds: 5),
  }) async {
    int attempt = 0;
    Object? lastError;

    while (attempt <= retries) {
      try {
        final res = await send();

        final shouldRetryResponse =
            res.statusCode >= 500 || res.statusCode == 429;

        if (attempt < retries && shouldRetryResponse) {
          final delay = _backoffWithJitter(attempt, baseDelay, maxDelay);
          await Future.delayed(delay);
          attempt++;
          continue;
        }

        return res;
      } catch (e) {
        lastError = e;
        final isNetworkError =
            e is SocketException || e is TimeoutException || e is http.ClientException;

        if (attempt >= retries || !isNetworkError) {
          rethrow;
        }

        final delay = _backoffWithJitter(attempt, baseDelay, maxDelay);
        await Future.delayed(delay);
        attempt++;
      }
    }

    throw lastError ?? Exception('Request failed after $retries retries');
  }

  static Duration _backoffWithJitter(
    int attempt,
    Duration baseDelay,
    Duration maxDelay,
  ) {
    final backoffMs =
        baseDelay.inMilliseconds * pow(2, attempt).toInt(); // exponential
    final capped = min(backoffMs, maxDelay.inMilliseconds);
    final jitter = Random().nextInt(max(1, capped ~/ 2)); // 0–50% jitter
    return Duration(
      milliseconds: min(capped + jitter, maxDelay.inMilliseconds),
    );
  }
}

