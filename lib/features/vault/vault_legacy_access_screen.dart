import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultLegacyAccessScreen extends StatefulWidget {
  const VaultLegacyAccessScreen({super.key});

  @override
  State<VaultLegacyAccessScreen> createState() => _VaultLegacyAccessScreenState();
}

class _VaultLegacyAccessScreenState extends State<VaultLegacyAccessScreen> {
  bool enabled = true;
  bool soft = true;
  bool approval = true;
  bool timerEnabled = false;

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
                    title: 'Legacy Access',
                    subtitle: 'Trusted person & conditions',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ToggleRow(
                          icon: Icons.person,
                          title: 'Trusted Person',
                          subtitle: 'Sarah Stevens',
                          value: enabled,
                          onChanged: (v) => setState(() => enabled = v),
                        ),
                        const SizedBox(height: 12),
                        GlassContainer(
                          radius: 18,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.rule, color: Colors.white.withOpacity(0.85)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Conditions',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _ChipLine(
                                label: 'Inactivity: 6 months',
                                active: true,
                                onTap: () {},
                              ),
                              const SizedBox(height: 10),
                              _ChipLine(
                                label: 'Soft mode',
                                active: soft,
                                onTap: () => setState(() => soft = !soft),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ToggleRow(
                          icon: Icons.verified_user,
                          title: 'Approval',
                          subtitle: 'Approved by Emma Stevens',
                          value: approval,
                          onChanged: (v) => setState(() => approval = v),
                          trailing: approval
                              ? Icon(Icons.check_circle, color: Colors.white.withOpacity(0.85))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _ToggleRow(
                          icon: Icons.timer,
                          title: 'Settings Timer',
                          subtitle: 'Set a history / auto log timer',
                          value: timerEnabled,
                          onChanged: (v) => setState(() => timerEnabled = v),
                        ),
                        const SizedBox(height: 14),
                        VaultPillButton(
                          label: 'Security & Trust',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.vaultSecurityTrust),
                        ),
                      ],
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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ],
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white.withOpacity(0.9),
          ),
        ],
      ),
    );
  }
}

class _ChipLine extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChipLine({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 18,
              color: Colors.white.withOpacity(0.75),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Colors.white.withOpacity(0.78), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
