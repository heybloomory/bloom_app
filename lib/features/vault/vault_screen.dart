import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.vault,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.09,
              child: Image.asset(
                'assets/images/sample.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VaultTopBar(
                    title: 'My Vault',
                    subtitle: 'Private & Secure',
                  ),
                  const SizedBox(height: 16),

                  // Hero safe card
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 190,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.10),
                                Colors.white.withOpacity(0.02),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock,
                              size: 84,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Locked Memories, Private & Secure',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        VaultOptionTile(
                          icon: Icons.lock_outline,
                          title: 'Private Memories',
                          subtitle: 'Face ID / PIN required',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.vaultPrivateUnlock,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VaultOptionTile(
                          icon: Icons.family_restroom,
                          title: 'Family Vault',
                          subtitle: 'Invite family with permissions',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.vaultFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VaultOptionTile(
                          icon: Icons.schedule,
                          title: 'Time‑Locked Memories',
                          subtitle: 'Capsules that open later',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.vaultTimeLocked,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VaultOptionTile(
                          icon: Icons.storage,
                          title: 'Manage Storage',
                          subtitle: 'Usage, upgrades & cleanup',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.vaultManageStorage,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Legacy Access',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.86),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key, color: Colors.white.withOpacity(0.88)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Add a trusted person who can access your vault in the future',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.74),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Switch(
                              value: true,
                              onChanged: (_) {},
                              activeThumbColor: Colors.white.withOpacity(0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: VaultPillButton(
                            label: 'Set Up Legacy Contact',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.vaultLegacyAccess,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.vaultSecurityTrust,
                            ),
                            child: Text(
                              'Security & Trust',
                              style: TextStyle(color: Colors.white.withOpacity(0.75)),
                            ),
                          ),
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
