import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'auth_session.dart';
import '../../services/api_service.dart';

class UserApiService {
  UserApiService._();
  static Map<String, dynamic>? _cachedUser;

  static Map<String, dynamic>? get cachedUser => _cachedUser;

  static Future<Map<String, dynamic>> getMe() async {
    final token = await AuthSession.getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated with backend.');
    }
    final response = await ApiService.get('/api/users/me');
    final data = _safeJson(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _cachedUser = user;
        return user;
      }
      _cachedUser = data;
      return data;
    }
    throw Exception((data['message'] ?? 'Could not load profile').toString());
  }

  static Future<bool> isProfileCompleted() async {
    try {
      final me = await getMe();
      if (me['profileCompleted'] == true) return true;
      final name = (me['name'] ?? '').toString().trim();
      debugPrint('[profile] isProfileCompleted -> ${name.isNotEmpty}');
      return name.isNotEmpty;
    } catch (_) {
      debugPrint('[profile] isProfileCompleted -> false (error)');
      return false;
    }
  }

  static Future<void> updateMe({
    String? name,
    bool? profileCompleted,
  }) async {
    final token = await AuthSession.getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Not authenticated with backend.');
    }

    final response = await ApiService.patch('/api/users/me', {
      if (name != null) 'name': name.trim(),
      if (profileCompleted != null) 'profileCompleted': profileCompleted,
    });

    final data = _safeJson(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        _cachedUser = user;
      }
      return;
    }

    throw Exception((data['message'] ?? 'Could not update profile').toString());
  }

  static Future<void> completeProfile({required String name}) async {
    debugPrint('[profile] completeProfile:start name=$name');
    await updateMe(name: name, profileCompleted: true);
    final me = await getMe();
    debugPrint('[profile] completeProfile:done profileCompleted=${me['profileCompleted']} name=${me['name']}');
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
