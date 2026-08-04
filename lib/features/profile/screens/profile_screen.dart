import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/profile_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/missions/providers/missions_provider.dart';
import '../../../features/education/providers/chapters_provider.dart';
import '../../../features/sightings/providers/sightings_provider.dart';
import '../../../widgets/level_progress_bar.dart';
import '../../../widgets/firefly_background.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final missions = ref.watch(missionsProvider);
    final chapters = ref.watch(chaptersProvider);
    final sightings = ref.watch(sightingsProvider);
    final badges = allBadges;

    final points = user?.points ?? 0;
    final progress = AppConstants.getLevelProgress(points);
    final nextLevel = AppConstants.getLevelForPoints(points) + 1;
    final nextLevelName = AppConstants.levelNames[nextLevel] ?? 'Máximo nivel';
    final nextPts = AppConstants.levelThresholds[nextLevel];

    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const FireflyBackground(count: 10, intensity: 0.3),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go('/home'),
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: context.text.bodyMedium?.color, size: 20),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mi perfil',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: context.colors.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => context.go('/settings'),
                          icon: Icon(Icons.settings_outlined,
                              color: context.text.bodyMedium?.color),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),

                // ── Avatar & Name ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: isSmallScreen ? 80 : 96,
                          height: isSmallScreen ? 80 : 96,
                          decoration: BoxDecoration(
                            gradient: context.firefly.primaryGradient,
                            shape: BoxShape.circle,
                            boxShadow: context.firefly.glowShadow,
                          ),
                          child: Center(
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: isSmallScreen ? 36 : 42,
                                fontWeight: FontWeight.w800,
                                color: context.colors.onPrimary,
                              ),
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

                        const SizedBox(height: 10),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            user?.name ?? 'Juan',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ).animate(delay: 100.ms).fadeIn(),

                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: context.text.bodySmall?.color,
                          ),
                        ).animate(delay: 150.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),

                // ── Points & Level Card ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E2D50), Color(0xFF131929)],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(
                            color: context.colors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _StatBubble(
                                  value: '${user?.points ?? 0}',
                                  label: 'Puntos',
                                  emoji: '⚡',
                                  color: context.colors.primary,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white10,
                              ),
                              Expanded(
                                child: _StatBubble(
                                  value: 'Nv.${user?.level ?? 1}',
                                  label: user?.levelName ?? 'Observador',
                                  emoji: '🌟',
                                  color: context.colors.secondary,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Siguiente: $nextLevelName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: context.text.bodyMedium?.color,
                                  ),
                                ),
                              ),
                              if (nextPts != null)
                                Text(
                                  '$nextPts pts',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.secondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LevelProgressBar(progress: progress),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
                  ),
                ),

                // ── Stats Row ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        _MiniStat(
                          emoji: '🎯',
                          value: '${missions.completedCount}',
                          label: 'Misiones',
                          color: context.colors.primary,
                          isSmallScreen: isSmallScreen,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          emoji: '📖',
                          value:
                              '${chapters.chapters.where((c) => c.isCompleted).length}',
                          label: 'Capítulos',
                          color: context.firefly.accent,
                          isSmallScreen: isSmallScreen,
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          emoji: '✨',
                          value: '${sightings.sightings.length}',
                          label: 'Avistam.',
                          color: context.colors.secondary,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ).animate(delay: 300.ms).fadeIn(),
                  ),
                ),

                // ── Badges Title ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Text(
                      '🏅 Mis insignias',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ).animate(delay: 350.ms).fadeIn(),
                ),

                // ── Badges Grid (Fully Responsive Aspect Ratio) ────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallScreen ? 2 : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isSmallScreen ? 0.95 : 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final badge = badges[i];
                        final unlocked = badge.isUnlocked(points);
                        return _BadgeCard(badge: badge, unlocked: unlocked)
                            .animate(
                              delay: Duration(milliseconds: 350 + i * 60),
                            )
                            .fadeIn()
                            .scale(begin: const Offset(0.85, 0.85));
                      },
                      childCount: badges.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String value, label, emoji;
  final Color color;
  final bool isSmallScreen;

  const _StatBubble({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 20 : 24)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: isSmallScreen ? 22 : 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.text.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  final bool isSmallScreen;

  const _MiniStat({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 10 : 14, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 16 : 20)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: isSmallScreen ? 17 : 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  color: context.text.bodySmall?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeDefinition badge;
  final bool unlocked;

  const _BadgeCard({required this.badge, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? context.colors.primary.withValues(alpha: 0.1)
            : context.firefly.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? context.colors.primary.withValues(alpha: 0.35)
              : context.firefly.cardBorder,
          width: unlocked ? 1.5 : 1,
        ),
        boxShadow: unlocked ? context.firefly.glowShadow : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: unlocked ? 1.0 : 0.35,
            child: Text(
              badge.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: unlocked ? context.colors.onSurface : context.text.bodySmall?.color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (unlocked)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: context.firefly.greenGlow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '✓',
                style: TextStyle(
                  fontSize: 9.5,
                  color: context.colors.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
