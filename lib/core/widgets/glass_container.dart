import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // ✅ Dark glass tint (this is what fixes the “white bar” issue)
            color: const Color(0xFF0B0B12).withOpacity(0.35),

            // ✅ subtle border for glass edge
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),

            // optional: inner gradient makes it look premium
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.02),
              ],
            ),

            borderRadius: BorderRadius.circular(radius),
          ),
          child: child,
        ),
      ),
    );
  }
}
