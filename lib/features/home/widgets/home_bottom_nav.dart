import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.firefly.cardBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Inicio',
                isActive: navigationShell.currentIndex == 0,
                onTap: () => navigationShell.goBranch(0, initialLocation: navigationShell.currentIndex == 0),
              ),
              _buildNavItem(
                context,
                icon: Icons.menu_book_rounded,
                label: 'Aprender',
                isActive: navigationShell.currentIndex == 1,
                onTap: () => navigationShell.goBranch(1, initialLocation: navigationShell.currentIndex == 1),
              ),
              _buildNavItem(
                context,
                icon: Icons.sports_esports_rounded,
                label: 'Jugar',
                isActive: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(2, initialLocation: navigationShell.currentIndex == 2),
              ),
              _buildNavItem(
                context,
                icon: Icons.map_rounded,
                label: 'Explorar',
                isActive: navigationShell.currentIndex == 3,
                onTap: () => navigationShell.goBranch(3, initialLocation: navigationShell.currentIndex == 3),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_rounded,
                label: 'Opciones',
                isActive: navigationShell.currentIndex == 4,
                onTap: () => navigationShell.goBranch(4, initialLocation: navigationShell.currentIndex == 4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? context.colors.primary : context.colors.onSurface.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      label: label,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: isActive
              ? BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
