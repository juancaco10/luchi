import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/mission_model.dart';
import '../providers/missions_provider.dart';
import '../../../widgets/firefly_background.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const FireflyBackground(count: 8, intensity: 0.25),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: context.text.bodyMedium?.color, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Misiones',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.colors.onSurface,
                            ),
                          ),
                          Text(
                            'Actúa, gana puntos, protege',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: context.text.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 16),

                // Progress summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProgressSummary(context, state),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: state.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              color: context.colors.primary))
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          children: [
                            if (state.dailyMissions.isNotEmpty) ...[
                              _SectionHeader(
                                  title: 'Misiones de Guardián',
                                  emoji: '🌅',
                                  subtitle: 'Actividades para proteger la naturaleza'),
                              const SizedBox(height: 10),
                              ...state.dailyMissions.asMap().entries.map(
                                    (e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _MissionListCard(
                                        mission: e.value,
                                        onTap: () => context
                                            .go('/missions/${e.value.id}'),
                                      ).animate(
                                        delay: Duration(
                                            milliseconds: e.key * 100),
                                      ).fadeIn().slideX(begin: 0.1, end: 0),
                                    ),
                                  ),
                              const SizedBox(height: 20),
                            ],
                            if (state.weeklyMissions.isNotEmpty) ...[
                              _SectionHeader(
                                  title: 'Retos Especiales',
                                  emoji: '🌿',
                                  subtitle: 'Mayor desafío, mayor recompensa'),
                              const SizedBox(height: 10),
                              ...state.weeklyMissions.asMap().entries.map(
                                    (e) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _MissionListCard(
                                        mission: e.value,
                                        onTap: () => context
                                            .go('/missions/${e.value.id}'),
                                      ).animate(
                                        delay: Duration(
                                            milliseconds:
                                                (e.key + 3) * 100),
                                      ).fadeIn().slideX(begin: 0.1, end: 0),
                                    ),
                                  ),
                              const SizedBox(height: 32),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context, MissionsState state) {
    final done = state.completedCount;
    final total = state.missions.length;
    final progress = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: context.firefly.cardGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: context.firefly.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$done de $total misiones',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.text.bodyMedium?.color,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: context.firefly.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn();
  }
}

// ── Section Header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title, emoji, subtitle;
  const _SectionHeader({
    required this.title, required this.emoji, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: context.text.bodySmall?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Mission List Card ─────────────────────────────────────────────

class _MissionListCard extends StatelessWidget {
  final MissionModel mission;
  final VoidCallback onTap;

  const _MissionListCard({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: mission.isCompleted
              ? const LinearGradient(
                  colors: [Color(0xFF0D2A1A), Color(0xFF131929)],
                )
              : context.firefly.missionGradient,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: mission.isCompleted
                ? context.colors.secondary.withValues(alpha: 0.25)
                : context.firefly.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: mission.isCompleted
                    ? context.firefly.greenGlow
                    : context.firefly.glow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  mission.isCompleted ? '✅' : mission.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Title + points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: mission.isCompleted
                          ? context.text.bodySmall?.color
                          : context.colors.onSurface,
                      decoration: mission.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '+${mission.pointsReward} pts',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: mission.isCompleted
                              ? context.text.bodySmall?.color
                              : context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow or check
            Icon(
              mission.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: mission.isCompleted ? context.colors.secondary : context.text.bodySmall?.color,
              size: mission.isCompleted ? 22 : 14,
            ),
          ],
        ),
      ),
    );
  }
}
