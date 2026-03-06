import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';
import 'firestore_sync_service.dart';

class AlbumApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in. Please login first.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> listRootAlbums() async {
    final uri = Uri.parse('$_baseUrl/api/albums'); // defaults to parentId=null
    final res = await http.get(uri, headers: await _headers());
    final data = _safeJson(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      final albums = (data['albums'] as List<dynamic>? ?? []);
      // Best-effort mirror to Firestore for Timeline.
      try {
        for (final a in albums) {
          if (a is Map) {
            await FirestoreSyncService.upsertAlbumFromApi(a.cast<String, dynamic>());
          }
        }
      } catch (_) {}
      return albums;
    }
    throw Exception((data['message'] ?? 'Failed to load albums').toString());
  }

  static Future<List<dynamic>> listChildAlbums(String parentId) async {
    final uri = Uri.parse('$_baseUrl/api/albums?parentId=$parentId');
    final res = await http.get(uri, headers: await _headers());
    final data = _safeJson(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      final albums = (data['albums'] as List<dynamic>? ?? []);
      try {
        for (final a in albums) {
          if (a is Map) {
            await FirestoreSyncService.upsertAlbumFromApi(a.cast<String, dynamic>());
          }
        }
      } catch (_) {}
      return albums;
    }
    throw Exception((data['message'] ?? 'Failed to load sub-albums').toString());
  }

  static Future<Map<String, dynamic>> getAlbum(String id) async {
    final uri = Uri.parse('$_baseUrl/api/albums/$id');
    final res = await http.get(uri, headers: await _headers());
    final data = _safeJson(res.body);

    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception((data['message'] ?? 'Failed to load album').toString());
  }

  static Future<Map<String, dynamic>> createAlbum({
    required String title,
    String? description,
    String? parentId, // null = root
  }) async {
    final uri = Uri.parse('$_baseUrl/api/albums');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'title': title.trim(),
        if (description != null) 'description': description.trim(),
        'parentId': parentId, // can be null
      }),
    );
    final data = _safeJson(res.body);

    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      final album = (data['album'] as Map).cast<String, dynamic>();

      // Mirror minimal album metadata to Firestore so Timeline shows it.
      // Safe: if Firebase isn't configured, it will throw and we ignore.
      try {
        await FirestoreSyncService.upsertAlbumFromApi(album);
      } catch (_) {}

      return album;
    }
    throw Exception((data['message'] ?? 'Failed to create album').toString());
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      return (jsonDecode(body) as Map).cast<String, dynamic>();
    } catch (_) {
      return {'message': body};
    }
  }
}
