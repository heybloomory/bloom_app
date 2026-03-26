import 'dart:convert';


import 'api_client.dart';

/// Remote timeline service backed by the Bloomory backend.
///
/// Endpoint: GET /api/timeline?limit=&offset=
class TimelineApiService {
  /// Returns the raw `memories` list from the backend timeline endpoint.
  static Future<List<Map<String, dynamic>>> fetchTimeline({
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await ApiClient.getJson(
      '/api/timeline',
      query: {
        'limit': '$limit',
        'offset': '$offset',
      },
    );

    final memories = data['memories'];
    if (memories is List) {
      return memories
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    throw Exception('Unexpected timeline response: ${jsonEncode(data)}');
  }
}

