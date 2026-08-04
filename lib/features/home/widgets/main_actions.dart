import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainActions extends StatelessWidget {
  const MainActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _ActionCard(
            title: 'Jugar',
            icon: 'assets/images/icon_jugar_3d.png',
            background: 'assets/images/card_bg_jugar.png',
            fallbackIcon: Icons.sports_esports_rounded,
            fallbackColor: const Color(0xFFF5D020),
            onTap: () => context.go('/game/level-1'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Capítulos',
            icon: 'assets/images/icon_aprender_3d.png',
            background: 'assets/images/card_bg_aprender.png',
            fallbackIcon: Icons.menu_book_rounded,
            fallbackColor: const Color(0xFF72E26E),
            onTap: () => context.go('/chapters'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            title: 'Mapa',
            icon: 'assets/images/icon_explorar_3d.png',
            background: 'assets/images/card_bg_explorar.png',
            fallbackIcon: Icons.map_rounded,
            fallbackColor: const Color(0xFF43D8FF),
            onTap: () => context.go('/map'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String icon;
  final String background;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.background,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 124,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: fallbackColor.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  background,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(color: fallbackColor.withValues(alpha: 0.15)),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      icon,
                      width: 44,
                      height: 44,
                      errorBuilder: (c, e, s) => Icon(fallbackIcon, color: fallbackColor, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C1B00),
                        shadows: [Shadow(color: Colors.white38, blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
