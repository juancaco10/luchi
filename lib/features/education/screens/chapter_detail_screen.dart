import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/chapter_model.dart';
import '../providers/chapters_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/reward_overlay.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class ChapterDetailScreen extends ConsumerStatefulWidget {
  final String chapterId;
  const ChapterDetailScreen({super.key, required this.chapterId});

  @override
  ConsumerState<ChapterDetailScreen> createState() =>
      _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends ConsumerState<ChapterDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _videoFinished = false;
  bool _showReward = false;
  bool _chapterCompleted = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final chapter = ref.read(chapterByIdProvider(widget.chapterId));
    if (chapter == null) return;

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(chapter.videoUrl),
    );
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: 16 / 9,
      autoPlay: false,
      looping: false,
      showControls: true,
      placeholder: Container(color: AppColors.cardSurface),
    );

    _videoController!.addListener(_videoListener);

    if (mounted) setState(() => _videoInitialized = true);
  }

  void _videoListener() {
    if (_videoController!.value.isInitialized) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      if (position >= duration && duration > Duration.zero) {
        if (!_videoFinished) {
          if (mounted) {
            setState(() => _videoFinished = true);
            final chapter = ref.read(chapterByIdProvider(widget.chapterId));
            if (chapter != null && !chapter.isCompleted) {
              _completeChapter(chapter);
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _completeChapter(ChapterModel chapter) async {
    if (_chapterCompleted) return;
    setState(() {
      _chapterCompleted = true;
      _showReward = true;
    });

    try {
      await ApiClient.instance.post(
        ApiEndpoints.completeChapter,
        data: {'chapter_id': chapter.id},
      );
    } catch (_) {
      // Continue even if offline to update local progress
    }

    ref.read(chaptersProvider.notifier).markCompleted(chapter.id);
    await ref.read(authProvider.notifier).addPoints(chapter.pointsReward);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showReward = false);
  }

  @override
  Widget build(BuildContext context) {
    final chapter = ref.watch(chapterByIdProvider(widget.chapterId));

    if (chapter == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Capítulo no encontrado')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Video Header ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  onPressed: () => context.go('/chapters'),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _videoInitialized
                      ? Chewie(controller: _chewieController!)
                      : Container(
                          color: AppColors.cardSurface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
              ),

              // ── Content ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Points badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⚡',
                                  style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                '+${chapter.pointsReward} puntos',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (chapter.isCompleted) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGlow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '✓ Completado',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    Text(
                      chapter.title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    Text(
                      chapter.description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 28),

                    // ── Facts ──────────────────────────────────────
                    if (chapter.facts.isNotEmpty) ...[
                      const Text(
                        '💡 Datos curiosos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...chapter.facts.asMap().entries.map((e) {
                        return _FactCard(fact: e.value, index: e.key);
                      }),
                      const SizedBox(height: 28),
                    ],

                    // ── Complete Button ────────────────────────────
                    if (!chapter.isCompleted && !_chapterCompleted && _videoFinished)
                      AppButton(
                        label: '¡Marcar como completado!',
                        onPressed: () => _completeChapter(chapter),
                        icon: Icons.check_circle_outline_rounded,
                      ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0)
                    else if (!chapter.isCompleted && !_chapterCompleted)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mira el video completo para desbloquear el siguiente nivel.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),

          // Reward overlay
          if (_showReward)
            RewardOverlay(
              points: chapter.pointsReward,
              message: '¡Capítulo completado!',
            ),
        ],
      ),
    );
  }
}

// ── Fact Card ─────────────────────────────────────────────────────

class _FactCard extends StatelessWidget {
  final String fact;
  final int index;

  const _FactCard({required this.fact, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accentLight,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 200 + index * 100)).fadeIn().slideX(begin: -0.1, end: 0);
  }
}

// Quiz widget removed
