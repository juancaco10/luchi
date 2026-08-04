import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/chapters_provider.dart';
import '../../../widgets/firefly_background.dart';

class ChaptersListScreen extends ConsumerWidget {
  const ChaptersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chaptersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const FireflyBackground(count: 8, intensity: 0.3),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textSecondary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capítulos',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Tu aventura de aprendizaje',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 16),

                // Chapters list
                Expanded(
                  child: state.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          itemCount: state.chapters.length,
                          itemBuilder: (ctx, i) {
                            final chapter = state.chapters[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ChapterCard(
                                chapter: chapter,
                                index: i,
                                onTap: chapter.isUnlocked
                                    ? () => context.go('/chapters/${chapter.id}')
                                    : null,
                              ).animate(
                                delay: Duration(milliseconds: i * 100),
                              ).fadeIn().slideX(begin: 0.2, end: 0),
                            );
                          },
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

class _ChapterCard extends StatelessWidget {
  final dynamic chapter;
  final int index;
  final VoidCallback? onTap;

  const _ChapterCard({
    required this.chapter,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !chapter.isUnlocked;
    final isDone = chapter.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isLocked ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isDone
                ? const LinearGradient(
                    colors: [Color(0xFF0D2A1A), Color(0xFF131929)],
                  )
                : AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isDone
                  ? AppColors.secondary.withOpacity(0.3)
                  : isLocked
                      ? AppColors.border.withOpacity(0.5)
                      : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Chapter number badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.secondaryGlow
                      : isLocked
                          ? AppColors.cardSurfaceLight.withOpacity(0.5)
                          : AppColors.accentGlow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone
                        ? AppColors.secondary.withOpacity(0.4)
                        : isLocked
                            ? AppColors.border.withOpacity(0.3)
                            : AppColors.accent.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock_rounded,
                          color: AppColors.textMuted, size: 22)
                      : isDone
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.secondary, size: 26)
                          : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentLight,
                              ),
                            ),
                ),
              ),

              const SizedBox(width: 16),

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isLocked
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '+${chapter.pointsReward} pts',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGlow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '✓ Completado',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (!isLocked)
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textMuted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
