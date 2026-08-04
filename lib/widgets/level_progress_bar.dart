import 'package:flutter/material.dart';
import '../core/theme/firefly_colors.dart';

/// Animated level progress bar with gradient fill and glow.
class LevelProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0

  const LevelProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = (width * progress).clamp(0.0, width);

        return Stack(
          children: [
            // Track
            Container(
              height: 10,
              width: width,
              decoration: BoxDecoration(
                color: context.firefly.cardBorder,
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            // Fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 10,
              width: fillWidth,
              decoration: BoxDecoration(
                gradient: context.firefly.primaryGradient,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),

            // Glow dot at tip
            if (fillWidth > 8)
              Positioned(
                left: fillWidth - 6,
                top: -1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primary.withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
