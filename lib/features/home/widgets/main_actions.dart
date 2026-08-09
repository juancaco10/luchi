import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';

class MainActions extends StatelessWidget {
  const MainActions({super.key, this.scale = 1.0});

  /// Factor de escala para el alto de las tarjetas — ver ScreenFitter.
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _ActionCard(
            title: 'JUGAR',
            subtitle: 'Quiz y desafíos',
            iconLight: 'assets/images/icon_jugar_3d.png',
            iconDark: 'assets/images/icon_jugar_3d.png',
            themeColor: const Color(0xFF90F055), // Bright green
            lightGradientColors: const [Color(0xFFE2F9D8), Color(0xFFF1FDF0)],
            onTap: () => context.go('/game'),
            scale: scale,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            title: 'CAPÍTULOS',
            subtitle: 'Aprende y descubre',
            iconLight: 'assets/images/icon_capitulos_3d.png',
            iconDark: 'assets/images/icon_capitulos_3d.png',
            themeColor: const Color(0xFFC48BFF), // Purple
            lightGradientColors: const [Color(0xFFEFE2FF), Color(0xFFF7F3FF)],
            onTap: () => context.go('/chapters'),
            scale: scale,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionCard(
            title: 'MAPA',
            subtitle: 'Explora avistamientos',
            iconLight: 'assets/images/icon_mapa_3d.png',
            iconDark: 'assets/images/icon_mapa_3d.png',
            themeColor: const Color(0xFF4DBBFF), // Blue
            lightGradientColors: const [Color(0xFFE1F3FF), Color(0xFFF1FAFF)],
            onTap: () => context.go('/map'),
            scale: scale,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconLight;
  final String iconDark;
  final Color themeColor;
  final List<Color> lightGradientColors;
  final VoidCallback onTap;
  final double scale;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.iconLight,
    required this.iconDark,
    required this.themeColor,
    required this.lightGradientColors,
    required this.onTap,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 155 * scale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF0F1115), Color(0xFF0A0C0F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: lightGradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: isDark
                ? Border.all(color: themeColor.withValues(alpha: 0.6), width: 1.5)
                : Border.all(color: themeColor.withValues(alpha: 0.8), width: 1.0),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      blurRadius: 15,
                      spreadRadius: -2,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14.0, left: 14.0, right: 14.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isDark)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43FF55).withValues(alpha: 0.6), // Green luminous glow
                                blurRadius: 25,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      Image.asset(
                        iconLight, // Holds the common .png path
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              // Text Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: isDark ? themeColor.withValues(alpha: 0.9) : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Arrow Button
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A1C20) : Colors.white,
                  border: isDark
                      ? Border.all(color: themeColor.withValues(alpha: 0.5), width: 1)
                      : null,
                  boxShadow: !isDark
                      ? [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: isDark ? themeColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
