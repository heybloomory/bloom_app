import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class UserApiService {
  UserApiService._();

  static Future<void> updateMe({
    String? name,
  }) async {
    final token = await AuthSession.getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated with backend.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/me');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) 'name': name.trim(),
      }),
    );

    final data = _safeJson(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return;
    }

    throw Exception((data['message'] ?? 'Could not update profile').toString());
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
