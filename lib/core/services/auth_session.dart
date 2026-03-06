import 'package:shared_preferences/shared_preferences.dart';

/// Very small helper to persist the Bloomory API JWT locally.
///
/// NOTE: This is not meant to be a full auth state manager yet.
/// It just stores/retrieves the token for API calls.
class AuthSession {
  static const _tokenKey = 'bloom_api_jwt';

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
