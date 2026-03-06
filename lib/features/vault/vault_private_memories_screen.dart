import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultPrivateMemoriesScreen extends StatelessWidget {
  const VaultPrivateMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      {
        'title': 'Anniversary Moments',
        'subtitle': '12 photos • 2 videos',
      },
      {
        'title': 'Personal Journal',
        'subtitle': '8 entries • locked',
      },
      {
        'title': 'Family Trip (Private)',
        'subtitle': '34 photos',
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
                    title: 'Private Memories',
                    subtitle: 'Unlocked',
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
                          'Your locked collections',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...items.map(
                          (it) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Opened "${it['title']}"')),
                                );
                              },
                              child: GlassContainer(
                                radius: 18,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: Row(
                                  children: [
                                    GlassContainer(
                                      radius: 14,
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(Icons.lock_open,
                                          color: Colors.white.withOpacity(0.9), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it['title']!,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.92),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            it['subtitle']!,
                                            style: TextStyle(
                                                color: Colors.white.withOpacity(0.65),
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        color: Colors.white.withOpacity(0.7)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: VaultPillButton(
                            label: 'Security & Trust',
                            onTap: () => Navigator.pushNamed(context, AppRoutes.vaultSecurityTrust),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
