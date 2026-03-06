import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultPrivateUnlockScreen extends StatelessWidget {
  const VaultPrivateUnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void unlock() {
      Navigator.pushNamed(context, AppRoutes.vaultPrivateMemories);
    }

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
                    subtitle: 'Face ID or PIN Required',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          height: 240,
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, size: 72, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(height: 10),
                              Text(
                                'Face ID or PIN Required',
                                style: TextStyle(color: Colors.white.withOpacity(0.75)),
                              ),
                              const SizedBox(height: 12),
                              _PinDots(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        VaultPillButton(label: 'Unlock With Face ID', onTap: unlock),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showPinSheet(context, onDone: unlock),
                          child: GlassContainer(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Center(
                              child: Text(
                                'Use PIN',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

class _PinDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

void _showPinSheet(BuildContext context, {required VoidCallback onDone}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: GlassContainer(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter PIN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _PinDots(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(9, (i) => i + 1)
                      .map(
                        (n) => _PinKey(
                          label: '$n',
                          onTap: () {},
                        ),
                      )
                      .toList()
                    ..addAll([
                      _PinKey(label: '⌫', onTap: () {}),
                      _PinKey(label: '0', onTap: () {}),
                      _PinKey(
                        label: 'OK',
                        onTap: () {
                          Navigator.pop(context);
                          onDone();
                        },
                      ),
                    ]),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PinKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 50,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          radius: 14,
          padding: const EdgeInsets.all(0),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
