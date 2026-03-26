import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

class PersonalizedContent {
  final List<PersonalizedBanner> banners;
  final List<PersonalizedOffer> offers;
  final List<PersonalizedRecommendation> recommendations;

  const PersonalizedContent({
    required this.banners,
    required this.offers,
    required this.recommendations,
  });

  factory PersonalizedContent.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PersonalizedContent(
      banners: parseList(json['banners'], PersonalizedBanner.fromJson),
      offers: parseList(json['offers'], PersonalizedOffer.fromJson),
      recommendations: parseList(
        json['recommendations'],
        PersonalizedRecommendation.fromJson,
      ),
    );
  }
}

class PersonalizedBanner {
  final String id;
  final String title;
  final String subtitle;
  final String target;

  const PersonalizedBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.target,
  });

  factory PersonalizedBanner.fromJson(Map<String, dynamic> json) {
    return PersonalizedBanner(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      target: (json['target'] ?? 'home').toString(),
    );
  }
}

class PersonalizedOffer {
  final String id;
  final String title;
  final String description;
  final String target;

  const PersonalizedOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
  });

  factory PersonalizedOffer.fromJson(Map<String, dynamic> json) {
    return PersonalizedOffer(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      target: (json['target'] ?? 'home').toString(),
    );
  }
}

class PersonalizedRecommendation {
  final String id;
  final String title;
  final String description;

  const PersonalizedRecommendation({
    required this.id,
    required this.title,
    required this.description,
  });

  factory PersonalizedRecommendation.fromJson(Map<String, dynamic> json) {
    return PersonalizedRecommendation(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class PersonalizationService {
  PersonalizationService._();

  static Future<PersonalizedContent> fetchPersonalizedContent() async {
    try {
      final response = await ApiService.get('/api/users/personalized-content');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return PersonalizedContent.fromJson(json);
      }
    } catch (e) {
      debugPrint('[PersonalizationService] fetch failed: $e');
    }
    return const PersonalizedContent(
      banners: <PersonalizedBanner>[],
      offers: <PersonalizedOffer>[],
      recommendations: <PersonalizedRecommendation>[],
    );
  }
}
