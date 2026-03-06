import 'package:flutter/material.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.settings,
    child: SingleChildScrollView(
  padding: const EdgeInsets.all(24),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
const Text(
  'Settings',
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  ),
),

            const SizedBox(height: 24),

            _SettingTile(
              icon: Icons.person,
              title: 'Profile',
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
            _SettingTile(
              icon: Icons.palette,
              title: 'Appearance',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () => Navigator.pushNamed(context, AppRoutes.settingsNotifications),
            ),
            _SettingTile(
              icon: Icons.logout,
              title: 'Logout',
              danger: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
          children: [
            Icon(
              icon,
              color: danger ? Colors.redAccent : Colors.white,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: danger ? Colors.redAccent : Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
          ),
        ),
      ),
    );
  }
}
