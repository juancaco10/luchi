import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../providers/chapters_provider.dart';
import '../../../widgets/firefly_background.dart';

class ChaptersListScreen extends ConsumerWidget {
  const ChaptersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chaptersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const FireflyBackground(count: 8, intensity: 0.3),
          SafeArea(
            child: Column(
              children: [
                // Header — pestaña de nivel superior (accesible desde el menú
                // inferior): sin flecha de retroceso, solo el título.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        'Aprender',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                const SizedBox(height: 16),

                // Chapters list
                Expanded(
                  child: state.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: context.colors.primary,
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
                : context.firefly.cardGradient,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: isDone
                  ? context.colors.secondary.withValues(alpha: 0.3)
                  : isLocked
                      ? context.firefly.cardBorder.withValues(alpha: 0.5)
                      : context.firefly.cardBorder,
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
                      ? context.firefly.greenGlow
                      : isLocked
                          ? context.firefly.cardSurface.withValues(alpha: 0.5)
                          : context.firefly.accentGlow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDone
                        ? context.colors.secondary.withValues(alpha: 0.4)
                        : isLocked
                            ? context.firefly.cardBorder.withValues(alpha: 0.3)
                            : context.firefly.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: isLocked
                      ? Icon(Icons.lock_rounded,
                          color: context.text.bodySmall?.color, size: 22)
                      : isDone
                          ? Icon(Icons.check_rounded,
                              color: context.colors.secondary, size: 26)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: context.firefly.accent,
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
                            ? context.text.bodySmall?.color
                            : context.colors.onSurface,
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
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isDone) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.firefly.greenGlow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '✓ Completado',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                color: context.colors.secondary,
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
                Icon(Icons.arrow_forward_ios_rounded,
                    color: context.text.bodySmall?.color, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
