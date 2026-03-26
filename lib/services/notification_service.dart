import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'analytics_service.dart';
import 'api_service.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationService {
  NotificationService._();

  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static GlobalKey<ScaffoldMessengerState>? _messengerKey;

  static Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;
    _messengerKey = messengerKey;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveDeviceToken(token);
    }

    messaging.onTokenRefresh.listen((token) {
      _saveDeviceToken(token);
    });

    FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? 'Bloomory';
      final body = message.notification?.body ?? 'New update';
      _messengerKey?.currentState?.showSnackBar(
        SnackBar(content: Text('$title: $body')),
      );
      await AnalyticsService.logEvent('notification_sent', params: {
        'type': message.data['type'] ?? 'general',
        'source': 'foreground',
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await AnalyticsService.logEvent('notification_opened', params: {
        'type': message.data['type'] ?? 'general',
      });
      _handleNotificationNavigation(message.data);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      await AnalyticsService.logEvent('notification_opened', params: {
        'type': initialMessage.data['type'] ?? 'general',
        'source': 'terminated',
      });
      _handleNotificationNavigation(initialMessage.data);
    }
  }

  static Future<void> _saveDeviceToken(String token) async {
    try {
      await ApiService.post('/api/users/save-device-token', <String, dynamic>{
        'token': token,
        'platform': 'android',
      });
    } catch (_) {
      // Token sync should not block app usage.
    }
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;
    final target = (data['target'] ?? 'home').toString();

    if (target == 'profile') {
      nav.pushNamed(AppRoutes.profileCompletion);
      return;
    }
    if (target == 'offers') {
      nav.pushNamed(AppRoutes.gifts);
      return;
    }
    nav.pushNamed(AppRoutes.dashboard);
  }
}
