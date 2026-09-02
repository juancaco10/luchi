import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? Colors.black : Colors.white,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          // El orden de los children ya es el orden visual (Home, Jugar,
          // Aprender, Publicaciones, Explorar — no el de índice de rama,
          // ver el comentario de más abajo), así que basta con agrupar
          // aquí para que ARRIBA/ABAJO/IZQUIERDA/DERECHA recorran el menú
          // en ese orden en vez de saltar a otra parte de la pantalla.
          child: FocusTraversalGroup(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              _buildNavItem(
                context,
                icon: Icons.home_rounded,
                label: 'Inicio',
                isActive: navigationShell.currentIndex == 0,
                onTap: () => navigationShell.goBranch(0,
                    initialLocation: navigationShell.currentIndex == 0),
              ),
              // Orden visual pedido: Home, Jugar, Aprender, Publicaciones,
              // Explorar. El índice de rama (1=Aprender/chapters,
              // 2=Jugar/game) no cambia, solo el orden en que se dibujan.
              _buildNavItem(
                context,
                icon: Icons.sports_esports_rounded,
                label: 'Jugar',
                isActive: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(2,
                    initialLocation: navigationShell.currentIndex == 2),
              ),
              _buildNavItem(
                context,
                icon: Icons.menu_book_rounded,
                label: 'Aprender',
                isActive: navigationShell.currentIndex == 1,
                onTap: () => navigationShell.goBranch(1,
                    initialLocation: navigationShell.currentIndex == 1),
              ),
              if (AppConstants.communityEnabled) ...[
                _buildNavItem(
                  context,
                  icon: Icons.dynamic_feed_rounded,
                  label: 'Publicaciones',
                  isActive: navigationShell.currentIndex == 4,
                  onTap: () => navigationShell.goBranch(4,
                      initialLocation: navigationShell.currentIndex == 4),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.map_rounded,
                  label: 'Explorar',
                  isActive: navigationShell.currentIndex == 3,
                  onTap: () => navigationShell.goBranch(3,
                      initialLocation: navigationShell.currentIndex == 3),
                ),
              ],
              ],
            ),
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
    final color = isActive
        ? context.colors.secondary
        : context.colors.onSurface.withValues(alpha: 0.5);

    // Menú de navegación principal de la app: era un GestureDetector
    // crudo, invisible para el travesal de foco de D-pad/teclado/mando —
    // con Material+InkWell queda enfocable y gana el borde de foco del
    // tema (ver AppTheme._withFocusRing / focusColor).
    return Semantics(
      button: true,
      label: label,
      selected: isActive,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          focusColor: context.firefly.focusRing.withValues(alpha: 0.24),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: isActive
                ? BoxDecoration(
                    color: context.colors.secondary.withValues(alpha: 0.1),
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
      ),
    );
  }
}
