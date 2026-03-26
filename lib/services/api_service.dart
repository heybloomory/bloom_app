import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/services/api_config.dart';
import 'auth_service.dart';

class ApiService {
  ApiService._();

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String path) async {
    return http.get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: await _headers());
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body) async {
    return http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }
}
