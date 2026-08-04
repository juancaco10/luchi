import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/firefly_colors.dart';

/// Full-screen reward overlay shown when completing missions/chapters.
/// Fades in with a celebration animation and auto-dismisses.
class RewardOverlay extends StatelessWidget {
  final int points;
  final String message;

  const RewardOverlay({
    super.key,
    required this.points,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Burst emoji
              const Text('🎉', style: TextStyle(fontSize: 80))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.colors.onSurface,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              // Points earned badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: context.firefly.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: context.firefly.glowShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '+$points puntos',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    curve: Curves.elasticOut,
                    duration: 600.ms,
                  ),

              const SizedBox(height: 24),

              Text(
                '¡Sigue protegiendo las luciérnagas! 🪲',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: context.text.bodyMedium?.color,
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
