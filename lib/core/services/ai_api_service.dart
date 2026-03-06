import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class AiApiService {
  static Future<String> ask(String message) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/ai/ask');

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data['reply'] ?? '').toString();
    }

    throw Exception('API error ${resp.statusCode}: ${resp.body}');
  }
}
