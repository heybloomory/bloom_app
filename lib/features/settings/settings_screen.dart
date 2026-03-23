import 'package:flutter/material.dart';
import '../../core/services/app_appearance_controller.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openAppearanceSheet() async {
    final controller = AppAppearanceController.instance;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: const Color(0xFF1A0E2A),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ThemeModeTile(
                      title: 'Light',
                      icon: Icons.light_mode_outlined,
                      selected: controller.themeMode == ThemeMode.light,
                      onTap: () => Navigator.pop(context, ThemeMode.light),
                    ),
                    _ThemeModeTile(
                      title: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      selected: controller.themeMode == ThemeMode.dark,
                      onTap: () => Navigator.pop(context, ThemeMode.dark),
                    ),
                    _ThemeModeTile(
                      title: 'System',
                      icon: Icons.brightness_auto,
                      selected: controller.themeMode == ThemeMode.system,
                      onTap: () => Navigator.pop(context, ThemeMode.system),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (selected == null) return;
    await controller.setThemeMode(selected);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appearance saved as ${switch (selected) {
            ThemeMode.dark => 'Dark',
            ThemeMode.system => 'System',
            ThemeMode.light => 'Light',
          }} theme.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = AppAppearanceController.instance.themeMode;
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
              subtitle: switch (themeMode) {
                ThemeMode.dark => 'Dark theme',
                ThemeMode.system => 'System default',
                ThemeMode.light => 'Light theme',
              },
              onTap: _openAppearanceSheet,
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
  final String? subtitle;
  final bool danger;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? Colors.redAccent : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.56),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
