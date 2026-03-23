import 'dart:convert';

import 'api_client.dart';

/// Search service for memories and albums using the Bloomory backend.
///
/// Endpoint: GET /api/search?q=
class SearchApiService {
  /// Returns the full search payload `{ memories: [...], albums: [...] }`.
  static Future<Map<String, List<Map<String, dynamic>>>> search(String query) async {
    final data = await ApiClient.getJson(
      '/api/search',
      query: {'q': query},
    );

    List<Map<String, dynamic>> _asList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    }

    final memories = _asList(data['memories']);
    final albums = _asList(data['albums']);

    return {
      'memories': memories,
      'albums': albums,
    };
  }
}

