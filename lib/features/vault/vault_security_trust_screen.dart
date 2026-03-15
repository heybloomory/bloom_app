import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultSecurityTrustScreen extends StatefulWidget {
  const VaultSecurityTrustScreen({super.key});

  @override
  State<VaultSecurityTrustScreen> createState() => _VaultSecurityTrustScreenState();
}

class _VaultSecurityTrustScreenState extends State<VaultSecurityTrustScreen> {
  bool biometric = true;
  bool e2ee = true;
  bool downloadDisabled = true;

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.vault,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.09,
              child: Image.asset('assets/images/sample.jpg', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VaultTopBar(
                    title: 'Security & Trust',
                    subtitle: 'Protect your vault',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  _ToggleTile(
                    icon: Icons.fingerprint,
                    title: 'Biometric Lock',
                    subtitle: 'Always require Face ID / Touch ID',
                    value: biometric,
                    onChanged: (v) => setState(() => biometric = v),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.shield,
                    title: 'End‑to‑End Encryption',
                    subtitle: 'Only you access your locked content',
                    onTap: () => setState(() => e2ee = !e2ee),
                    trailing: Switch(
                      value: e2ee,
                      onChanged: (v) => setState(() => e2ee = v),
                      activeThumbColor: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ToggleTile(
                    icon: Icons.download,
                    title: 'Download Disabled',
                    subtitle: 'Each year you can review the log',
                    value: downloadDisabled,
                    onChanged: (v) => setState(() => downloadDisabled = v),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.list_alt,
                    title: 'Vault Activity Log',
                    subtitle: 'See the last 200 activities',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity log coming soon.')),
                      );
                    },
                    trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: VaultPillButton(
                      label: 'Manage Activity Log',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manage log coming soon.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 22,
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 22,
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
