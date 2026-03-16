import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session.dart';

/// Media upload service for images/videos to Bloomory backend.
///
/// Endpoint: POST /api/media/upload (multipart/form-data)
class MediaApiService {
  static String get _baseUrl => ApiConfig.baseUrl;

  static Future<String> _token() async {
    final token = await AuthSession.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in. Please login first.');
    }
    return token;
  }

  /// Upload an image or video file to the backend using a File handle.
  ///
  /// Required form fields:
  /// - albumId
  /// - file (binary)
  /// Optional:
  /// - thumbnail (binary)
  /// - type: image|video (if not provided, backend infers from mimetype)
  ///
  /// Adds a 120s timeout around the multipart request to better support large uploads.
  static Future<Map<String, dynamic>> uploadMedia({
    required String albumId,
    required File file,
    File? thumbnail,
    String? type,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/media/upload');
    final token = await AuthSession.getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['albumId'] = albumId;
    if (type != null && type.isNotEmpty) {
      request.fields['type'] = type;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    if (thumbnail != null) {
      request.files.add(
        await http.MultipartFile.fromPath('thumbnail', thumbnail.path),
      );
    }

    http.StreamedResponse streamed;
    try {
      streamed = await request
          .send()
          .timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw Exception(
        'Upload timed out. Please check your network and try again.',
      );
    }

    final response = await http.Response.fromStream(streamed);

    Map<String, dynamic> _safeJson() {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } catch (_) {
        return {};
      }
    }

    final data = _safeJson();
    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['media'] as Map? ?? {});
    }

    final msg = (data['message'] ?? 'Media upload failed').toString();
    throw Exception(msg);
  }

  /// Upload media from in-memory bytes (e.g. compressed image) to an album.
  ///
  /// Endpoint and response semantics are the same as [uploadMedia].
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

    http.StreamedResponse streamed;
    try {
      streamed = await req
          .send()
          .timeout(const Duration(seconds: 120));
    } on TimeoutException {
      throw Exception(
        'Upload timed out. Please check your network and try again.',
      );
    }

    final body = await streamed.stream.bytesToString();
    final data = _safeJson(body);

    if ((streamed.statusCode == 200 || streamed.statusCode == 201) &&
        data['success'] == true) {
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

