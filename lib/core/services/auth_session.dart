import '../../services/auth_service.dart';

/// Very small helper to persist the Bloomory API JWT locally.
///
/// NOTE: This is not meant to be a full auth state manager yet.
/// It just stores/retrieves the token for API calls.
class AuthSession {
  static Future<void> setToken(String token) async {
    await AuthService.saveToken(token);
  }

  static Future<String?> getToken() async {
    return AuthService.getToken();
  }

  static Future<void> clear() async {
    await AuthService.deleteToken();
  }
}
