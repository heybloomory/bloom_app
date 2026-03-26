import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics get _instance =>
      _analytics ??= FirebaseAnalytics.instance;

  static Future<void> logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) async {
    try {
      final safe = <String, Object>{};
      params.forEach((key, value) {
        if (value != null) safe[key] = value;
      });
      await _instance.logEvent(
        name: name,
        parameters: safe.isEmpty ? null : safe,
      );
    } catch (_) {
      // Never block UX for analytics failures.
    }
  }
}
