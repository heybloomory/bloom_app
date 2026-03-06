import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

class MediaApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String> _token() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in. Please login first.');
    }
    return token;
  }

  static Future<Map<String, dynamic>> uploadToAlbum({
    required String albumId,
    required Uint8List bytes,
    required String fileName,
    Uint8List? thumbnailBytes,
    String? thumbnailFileName,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_baseUrl/api/media/upload');

    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';

    req.fields['albumId'] = albumId;

    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    // Optional thumbnail upload (preferred over CDN transform links).
    // Backend should accept 'thumbnail' field; if it doesn't, it will simply ignore.
    if (thumbnailBytes != null && thumbnailBytes.isNotEmpty) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'thumbnail',
          thumbnailBytes,
          filename: thumbnailFileName ?? 'thumb_$fileName',
        ),
      );
    }

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    final data = _safeJson(body);

    if ((streamed.statusCode == 200 || streamed.statusCode == 201) && data['success'] == true) {
      return (data['media'] as Map).cast<String, dynamic>();
    }
    throw Exception((data['message'] ?? 'Upload failed').toString());
  }

  static Map<String, dynamic> _safeJson(String body) {
    try {
      return (jsonDecode(body) as Map).cast<String, dynamic>();
    } catch (_) {
      return {'message': body};
    }
  }
}
