import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultTimeLockedScreen extends StatelessWidget {
  const VaultTimeLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      {
        'title': 'Open when Leo turns 18',
        'date': 'June 7, 2030',
        'note': 'No peeking — capsule sealed until birthday',
      },
      {
        'title': 'Open on our 10th anniversary',
        'date': 'May 18, 2026',
        'note': 'Second honeymoon. Each year gets better',
      },
    ];

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
                    title: 'Time‑Locked\nMemories',
                    subtitle: 'Capsules sealed until the date',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  ...items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlassContainer(
                        radius: 22,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_clock,
                                    color: Colors.white.withOpacity(0.88)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    it['title']!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              it['date']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.78),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              it['note']!,
                              style: TextStyle(color: Colors.white.withOpacity(0.66)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: VaultPillButton(
                                    label: 'View Details',
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Details for "${it['title']}"')),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: VaultPillButton(
                      label: 'Create Time Capsule',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Create capsule coming soon.')),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
