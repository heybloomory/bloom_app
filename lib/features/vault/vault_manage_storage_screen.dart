import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultManageStorageScreen extends StatefulWidget {
  const VaultManageStorageScreen({super.key});

  @override
  State<VaultManageStorageScreen> createState() => _VaultManageStorageScreenState();
}

class _VaultManageStorageScreenState extends State<VaultManageStorageScreen> {
  double usedGB = 14.8;
  double totalGB = 50.0;
  bool vaultStorageOn = true;

  @override
  Widget build(BuildContext context) {
    final pct = (usedGB / totalGB).clamp(0.0, 1.0);

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
                    title: 'Manage Storage',
                    subtitle: 'Usage & cleanup',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Usage',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${usedGB.toStringAsFixed(1)} GB of ${totalGB.toStringAsFixed(0)} GB used',
                                style: TextStyle(color: Colors.white.withOpacity(0.72)),
                              ),
                            ),
                            Switch(
                              value: vaultStorageOn,
                              onChanged: (v) => setState(() => vaultStorageOn = v),
                              activeColor: Colors.white.withOpacity(0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.55),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Upgrade/cleanup coming soon.')),
                            );
                          },
                          child: Center(
                            child: Text(
                              'Manage Storage  >',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VaultOptionTile(
                          icon: Icons.security,
                          title: 'Security & Trust',
                          subtitle: 'Biometric lock, encryption & logs',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.vaultSecurityTrust),
                        ),
                        const SizedBox(height: 12),
                        VaultOptionTile(
                          icon: Icons.person,
                          title: 'Legacy Access',
                          subtitle: 'Trusted person & conditions',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.vaultLegacyAccess),
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
