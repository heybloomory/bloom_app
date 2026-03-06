import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final String? currentRoute;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.child,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient, // ✅ GLOBAL GRADIENT
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
