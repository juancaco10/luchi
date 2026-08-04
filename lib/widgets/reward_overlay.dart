import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_colors.dart';

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
        color: Colors.black.withOpacity(0.75),
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
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              // Points earned badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.primaryGlowShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '+$points puntos',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnPrimary,
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
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
