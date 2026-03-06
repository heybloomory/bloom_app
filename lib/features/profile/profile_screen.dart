import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';

/// Profile UI reference (based on the mock you shared).
///
/// Route: AppRoutes.profile
/// Navigator.pushNamed(context, AppRoutes.profile);
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email?.split('@').first ?? 'User');

    return MainAppShell(
      currentRoute: AppRoutes.profile,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(displayName: displayName),
              const SizedBox(height: 18),
              const _StatsRow(),
              const SizedBox(height: 22),

              _SectionHeader(
                title: 'Photo Highlights',
                onViewAll: () {
                  // TODO: link to your highlights/album screen
                },
              ),
              const SizedBox(height: 12),
              const _HighlightsRow(),

              const SizedBox(height: 22),
              _SectionHeader(
                title: 'More Highlights',
                onViewAll: () {},
              ),
              const SizedBox(height: 12),
              const _HighlightsRow(compact: true),

              const SizedBox(height: 26),
              const _ProfileMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;

  const _ProfileHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          GlassContainer(
            radius: 44,
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white10,
              child: const Icon(Icons.person, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.white60),
              SizedBox(width: 6),
              Text(
                'Los Angeles, CA',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: const [
          _StatItem(value: '6,237', label: 'Memories'),
          _Divider(),
          _StatItem(value: '256', label: 'Vaulted Items'),
          _Divider(),
          _StatItem(value: '125', label: 'Connections'),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white.withOpacity(0.08),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
        const Spacer(),
        InkWell(
          onTap: onViewAll,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: const [
              Text('View All', style: TextStyle(color: Colors.white60)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.white54),
            ],
          ),
        )
      ],
    );
  }
}

class _HighlightsRow extends StatelessWidget {
  final bool compact;
  const _HighlightsRow({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final height = compact ? 110.0 : 135.0;
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _HighlightCard(title: 'Beach', count: '6,237', icon: Icons.photo),
          _HighlightCard(title: 'Vault', count: '256', icon: Icons.lock_outline),
          _HighlightCard(title: 'People', count: '125', icon: Icons.people_outline),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;

  const _HighlightCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.white.withOpacity(0.04),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white24, size: 46),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    count,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.person_outline,
          title: 'Account Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        _MenuTile(
          icon: Icons.notifications_none,
          title: 'Notification Settings',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        _MenuTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        _MenuTile(
          icon: Icons.power_settings_new,
          title: 'Sign Out',
          danger: true,
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              );
            }
          },
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : Colors.white;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: GlassContainer(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 16),
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
