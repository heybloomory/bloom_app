import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../core/widgets/glass_container.dart';

class MainAppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const MainAppShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          extendBody: true, // ✅ IMPORTANT: makes bottom bar float over background
          backgroundColor: Colors.transparent, // ✅ avoid white surface
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF12061F), Color(0xFF1B0F2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                if (isDesktop) _SideBar(currentRoute: currentRoute),
                Expanded(child: child),
              ],
            ),
          ),

          // 👇 MOBILE ONLY
          bottomNavigationBar:
              isDesktop ? null : _MobileBottomNav(currentRoute: currentRoute),
        );
      },
    );
  }
}

class _SideBar extends StatelessWidget {
  final String currentRoute;

  const _SideBar({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: GlassContainer(
        radius: 0,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SafeArea(
          child: Column(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(height: 32),

              _NavItem(
                icon: Icons.timeline,
                route: AppRoutes.dashboard,
                currentRoute: currentRoute,
              ),
              _NavItem(
                icon: Icons.card_giftcard,
                route: AppRoutes.gifts,
                currentRoute: currentRoute,
              ),
              _NavItem(
                icon: Icons.design_services,
                route: AppRoutes.service,
                currentRoute: currentRoute,
              ),
              _NavItem(
                icon: Icons.menu_book,
                route: AppRoutes.learn,
                currentRoute: currentRoute,
              ),
              _NavItem(
                icon: Icons.lock_outline,
                route: AppRoutes.vault,
                currentRoute: currentRoute,
              ),

              const Spacer(),

              _NavItem(
                icon: Icons.settings,
                route: AppRoutes.settings,
                currentRoute: currentRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.route,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = route == currentRoute;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        child: GlassContainer(
          radius: 16,
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.25) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileBottomNav extends StatelessWidget {
  final String currentRoute;

  const _MobileBottomNav({required this.currentRoute});

  int _indexFromRoute() {
    switch (currentRoute) {
      case AppRoutes.dashboard:
        return 0;
      case AppRoutes.gifts:
        return 1;
      case AppRoutes.service:
        return 2;
      case AppRoutes.vault:
        return 4;
      case AppRoutes.learn:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexFromRoute();

    void go(String route) {
      if (route == currentRoute) return;
      Navigator.pushReplacementNamed(context, route);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          // ✅ gives depth so it looks like your reference
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassContainer(
            radius: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  label: 'Timeline',
                  icon: Icons.timeline,
                  active: idx == 0,
                  onTap: () => go(AppRoutes.dashboard),
                ),
                _BottomNavItem(
                  label: 'GIFT',
                  icon: Icons.card_giftcard,
                  active: idx == 1,
                  onTap: () => go(AppRoutes.gifts),
                ),
                _BottomNavItem(
                  label: 'SERVICE',
                  icon: Icons.design_services,
                  active: idx == 2,
                  onTap: () => go(AppRoutes.service),
                ),
                _BottomNavItem(
                  label: 'Learn',
                  icon: Icons.menu_book,
                  active: idx == 3,
                  onTap: () => go(AppRoutes.learn),
                ),
                _BottomNavItem(
                  label: 'Vault',
                  icon: Icons.lock_outline,
                  active: idx == 4,
                  onTap: () => go(AppRoutes.vault),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : Colors.white.withOpacity(0.78);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
