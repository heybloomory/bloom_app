import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool appNotifications = true;
  bool courseUpdates = true;
  bool marketing = false;
  bool storageAlerts = true;

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.settings,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const GlassContainer(
                    radius: 14,
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Notifications',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ToggleTile(
              title: 'App notifications',
              subtitle: 'Enable/disable all notifications',
              value: appNotifications,
              onChanged: (v) => setState(() => appNotifications = v),
            ),
            _ToggleTile(
              title: 'Course updates',
              subtitle: 'New lessons, content, and reminders',
              value: courseUpdates,
              onChanged: appNotifications ? (v) => setState(() => courseUpdates = v) : null,
            ),
            _ToggleTile(
              title: 'Storage alerts',
              subtitle: 'Vault usage, safety & access alerts',
              value: storageAlerts,
              onChanged: appNotifications ? (v) => setState(() => storageAlerts = v) : null,
            ),
            _ToggleTile(
              title: 'Offers & marketing',
              subtitle: 'Discounts, partner offers, promotions',
              value: marketing,
              onChanged: appNotifications ? (v) => setState(() => marketing = v) : null,
            ),
            const SizedBox(height: 14),
            const GlassContainer(
              radius: 18,
              padding: EdgeInsets.all(14),
              child: Text(
                'This is a UI page (demo). Connect these toggles to your backend preferences later.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: disabled ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: disabled ? Colors.white24 : Colors.white54,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
