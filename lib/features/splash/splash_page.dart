import 'dart:async';
import 'package:flutter/material.dart';
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
  void _goLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _goDashboard() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  void _goProfile() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.profileCompletion);
  }

  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    await AnalyticsService.logEvent('app_open');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    print("🔵 SPLASH START");

    final token = await AuthService.getToken();
    print("🔵 TOKEN: $token");
    if (token == null || token.trim().isEmpty) {
      print("🔴 ROUTE -> LOGIN (NO TOKEN)");
      if (!mounted) return;
      _goLogin();
      return;
    }

    final isExpired = AuthService.isTokenExpired(token);
    if (isExpired) {
      print("🔴 ROUTE -> LOGIN (TOKEN EXPIRED)");
      await AuthService.logout();
      if (!mounted) return;
      _goLogin();
      return;
    }

    final user = await AuthService.getUser();
    final completed = user?["profileCompleted"] == true;
    print("🟢 FINAL USER: $user");
    print("🟢 PROFILE COMPLETED: ${user?["profileCompleted"]}");
    if (!mounted) return;
    if (user == null) {
      print("🔴 ROUTE -> LOGIN (NO USER)");
      _goLogin();
      return;
    }
    if (completed) {
      print("🟢 ROUTE -> DASHBOARD");
      _goDashboard();
      return;
    }
    print("🟡 ROUTE -> PROFILE COMPLETION");
    _goProfile();
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
