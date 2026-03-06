import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'vault_widgets.dart';

class VaultFamilyScreen extends StatefulWidget {
  const VaultFamilyScreen({super.key});

  @override
  State<VaultFamilyScreen> createState() => _VaultFamilyScreenState();
}

class _VaultFamilyScreenState extends State<VaultFamilyScreen> {
  bool _permissionsEnabled = true;

  final List<_FamilyMember> _members = [
    _FamilyMember(name: 'Emma Stevens', role: 'Permissions', action: 'Owner'),
    _FamilyMember(name: 'Adam', role: 'Memories', action: 'Add Memories'),
    _FamilyMember(name: 'Sophie', role: 'Memories', action: 'View Only'),
    _FamilyMember(name: 'Sarah', role: 'Memories', action: 'Request Access'),
  ];

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
                    title: 'Family Vault',
                    subtitle: 'Share with control',
                    showBack: true,
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/profile.jpg',
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emma Stevens',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Permissions',
                                    style: TextStyle(color: Colors.white.withOpacity(0.65)),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _permissionsEnabled,
                              onChanged: (v) => setState(() => _permissionsEnabled = v),
                              activeColor: Colors.white.withOpacity(0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Family Members',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ..._members.skip(1).map((m) => _MemberRow(member: m)),
                        const SizedBox(height: 14),
                        VaultPillButton(
                          label: 'Invite Member',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite flow coming soon.')),
                            );
                          },
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

class _MemberRow extends StatelessWidget {
  final _FamilyMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/profile.jpg',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 5),
                      Text(
                        member.role,
                        style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ActionChip(label: member.action),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  const _ActionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.88),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FamilyMember {
  final String name;
  final String role;
  final String action;
  const _FamilyMember({required this.name, required this.role, required this.action});
}
