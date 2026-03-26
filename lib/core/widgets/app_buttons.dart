import 'package:flutter/material.dart';

import 'glass_container.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return Opacity(
      opacity: disabled ? 0.68 : 1,
      child: GestureDetector(
        onTap: disabled ? null : onPressed,
        child: Container(
          height: 52,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD79A4E).withOpacity(0.90),
                const Color(0xFFB66A2F).withOpacity(0.90),
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 18, color: Colors.white),
              if (isLoading || icon != null) const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool selected;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Colors.white24 : Colors.white10,
          border: Border.all(
            color: selected ? Colors.white54 : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.white70),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppIconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  const AppIconCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 40,
        height: 40,
        child: GlassContainer(
          radius: 20,
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white70, size: size),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}
