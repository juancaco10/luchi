import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/missions_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/reward_overlay.dart';

class MissionDetailScreen extends ConsumerStatefulWidget {
  final String missionId;
  const MissionDetailScreen({super.key, required this.missionId});

  @override
  ConsumerState<MissionDetailScreen> createState() =>
      _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen> {
  bool _showReward = false;
  bool _isSubmitting = false;
  int _earnedPoints = 0;

  Future<void> _complete() async {
    setState(() => _isSubmitting = true);
    try {
      final pts = await ref
          .read(missionsProvider.notifier)
          .completeMission(int.parse(widget.missionId));
      if (pts > 0) {
        await ref.read(authProvider.notifier).addPoints(pts);
        if (!mounted) return;
        setState(() {
          _earnedPoints = pts;
          _showReward = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _showReward = false);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = ref.watch(missionByIdProvider(widget.missionId));

    if (mission == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
            child: Text('Misión no encontrada',
                style: TextStyle(color: context.colors.onSurface))),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.go('/missions'),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.firefly.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.firefly.cardBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: context.text.bodyMedium?.color, size: 18),
                    ),
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                  ),

                  const SizedBox(height: 24),

                  // Big icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: mission.isCompleted
                            ? context.firefly.greenGradient
                            : context.firefly.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (mission.isCompleted
                                    ? context.colors.secondary
                                    : context.colors.primary)
                                .withValues(alpha: 0.35),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          mission.isCompleted ? '✅' : mission.icon,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                        )
                        .fadeIn(),
                  ),

                  const SizedBox(height: 28),

                  // Type badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: mission.type.name == 'daily'
                            ? context.firefly.accentGlow
                            : context.firefly.glow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: mission.type.name == 'daily'
                              ? context.firefly.accent.withValues(alpha: 0.4)
                              : context.colors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        mission.type.name == 'daily'
                            ? '🌅 Misión diaria'
                            : '🌿 Misión semanal',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: mission.type.name == 'daily'
                              ? context.firefly.accent
                              : context.colors.primary,
                        ),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    mission.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.colors.onSurface,
                      height: 1.2,
                    ),
                  )
                      .animate(delay: 150.ms)
                      .fadeIn()
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    mission.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      color: context.text.bodyMedium?.color,
                      height: 1.6,
                    ),
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // How to
                  if (mission.howTo != null) ...[
                    _InfoBlock(
                      icon: '📋',
                      title: '¿Cómo hacerlo?',
                      content: mission.howTo!,
                      color: context.firefly.accent,
                      delay: 250,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Tip
                  if (mission.tip != null) ...[
                    _InfoBlock(
                      icon: '💡',
                      title: '¿Por qué importa?',
                      content: mission.tip!,
                      color: context.colors.secondary,
                      delay: 300,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Points reward
                  _PointsRewardCard(points: mission.pointsReward),

                  const SizedBox(height: 32),

                  // Complete button
                  if (!mission.isCompleted)
                    AppButton(
                      label: '¡Misión cumplida!',
                      onPressed: _isSubmitting ? null : _complete,
                      isLoading: _isSubmitting,
                      icon: Icons.check_circle_rounded,
                      gradient: context.firefly.greenGradient,
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3, end: 0)
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.firefly.greenGlow,
                        borderRadius:
                            BorderRadius.circular(AppConstants.buttonRadius),
                        border: Border.all(
                            color: context.colors.secondary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: context.colors.secondary),
                          const SizedBox(width: 10),
                          Text(
                            '¡Misión completada!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          if (_showReward)
            RewardOverlay(
              points: _earnedPoints,
              message: '¡Misión completada!',
            ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String icon, title, content;
  final Color color;
  final int delay;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: context.text.bodyMedium?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

class _PointsRewardCard extends StatelessWidget {
  final int points;
  const _PointsRewardCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: context.firefly.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            '+$points puntos al completar',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: context.colors.onPrimary,
            ),
          ),
        ],
      ),
    ).animate(delay: 350.ms).fadeIn();
  }
}
