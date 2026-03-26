import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_session.dart';
import '../../core/services/user_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await AnalyticsService.logEvent('app_open');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final validSession = await AuthService.validateSession();
    if (!mounted) return;
    if (!validSession) {
      await AuthSession.clear();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }
    final completed = await UserApiService.isProfileCompleted();
    debugPrint('[profile] splash route completed=$completed');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      completed ? AppRoutes.dashboard : AppRoutes.profileCompletion,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: const Center(
          child: Text(
            'BloomoryAI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
