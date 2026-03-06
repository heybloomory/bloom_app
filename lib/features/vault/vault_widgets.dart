import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';

class VaultTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  const VaultTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.white.withOpacity(0.85)),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.white.withOpacity(0.70)),
                ),
              ],
            ],
          ),
        ),
        Icon(Icons.notifications_none, color: Colors.white.withOpacity(0.85)),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Image.asset(
            'assets/images/profile.jpg',
            width: 38,
            height: 38,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class VaultPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const VaultPillButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class VaultOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const VaultOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            GlassContainer(
              radius: 14,
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
