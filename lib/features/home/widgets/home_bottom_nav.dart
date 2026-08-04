import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeBottomNav extends ConsumerWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131929) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE8EEF5))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Inicio',
                isActive: true,
                isDark: isDark,
                onTap: () {},
              ),
              _buildNavItem(
                context,
                icon: Icons.map_rounded,
                label: 'Mapa',
                isActive: false,
                isDark: isDark,
                onTap: () => context.go('/map'),
              ),
              _buildNavItem(
                context,
                icon: Icons.menu_book_rounded,
                label: 'Aprender',
                isActive: false,
                isDark: isDark,
                onTap: () => context.go('/chapters'),
              ),
              _buildNavItem(
                context,
                icon: Icons.person_rounded,
                label: 'Perfil',
                isActive: false,
                isDark: isDark,
                onTap: () => context.go('/profile'),
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
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final color = isActive 
      ? (isDark ? const Color(0xFF72E26E) : const Color(0xFF438A3C)) 
      : (isDark ? Colors.white54 : const Color(0xFF8F9FB9));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: (isDark ? const Color(0xFF72E26E) : const Color(0xFF438A3C)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
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
    );
  }
}
