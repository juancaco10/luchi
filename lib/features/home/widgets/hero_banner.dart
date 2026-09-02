import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/firefly_colors.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        gradient: context.firefly.cardGradient,
        boxShadow: context.firefly.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descubre el mundo de las luciérnagas',
            style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Aprende, juega y comparte tus avistamientos',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 12),

          // Button
          Semantics(
            button: true,
            label: 'Explorar ahora, ir a capítulos',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () => context.go('/chapters'),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: context.firefly.greenGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: context.firefly.greenGlowShadow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // El fondo del botón es el mismo verde brillante en ambos
                      // temas (greenGradient no varía con isDark), así que el
                      // texto se fija en oscuro en vez de derivarlo del tema.
                      Text(
                        'Explorar ahora',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1E19),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF0F1E19)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
