import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class OfferMessage {
  final String title;
  final String body;

  const OfferMessage({required this.title, required this.body});
}

class OfferService {
  OfferService._();

  static Future<OfferMessage?> getTimelineOffer() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/offers/active');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final offer = data['offer'] is Map<String, dynamic>
              ? data['offer'] as Map<String, dynamic>
              : data;
          final title = (offer['title'] ?? '').toString().trim();
          final body = (offer['message'] ?? offer['body'] ?? '')
              .toString()
              .trim();
          if (title.isNotEmpty || body.isNotEmpty) {
            return OfferMessage(
              title: title.isEmpty ? 'Special Offer' : title,
              body: body.isEmpty ? 'Check today\'s offer in Bloomory.' : body,
            );
          }
        }
      }
    } catch (_) {
      // fallback below
    }
    return const OfferMessage(
      title: 'Diwali Offer',
      body: 'Storage fee only ₹300 for this festive period.',
    );
  }
}
