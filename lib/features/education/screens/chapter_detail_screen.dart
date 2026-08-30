import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';
import '../models/chapter_model.dart';
import '../providers/chapters_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/reward_overlay.dart';
import '../../../widgets/hardware_back_route.dart';
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
  bool _videoError = false;
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

    try {
      // Los capítulos reproducen su video empaquetado en el APK
      // (`assets/videos/{id}.mp4`), así Aprender funciona sin conexión. Solo
      // si `videoUrl` del modelo es una URL externa (backend sin bundle) se
      // cae a reproducción por red.
      final isAsset = chapter.videoUrl.startsWith('assets/');
      _videoController = isAsset
          ? VideoPlayerController.asset(chapter.videoUrl)
          : VideoPlayerController.networkUrl(Uri.parse(chapter.videoUrl));
      await _videoController!.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        aspectRatio: 16 / 9,
        autoPlay: false,
        looping: false,
        showControls: true,
        placeholder: Container(color: context.firefly.cardSurface),
      );

      _videoController!.addListener(_videoListener);

      if (mounted) setState(() => _videoInitialized = true);
    } catch (_) {
      // Vídeo caído, URL rota o sin conexión: sin esto el niño se queda
      // mirando un spinner girando para siempre sin ninguna explicación.
      if (mounted) setState(() => _videoError = true);
    }
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
      await ref.read(apiClientProvider).post(
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
      return HardwareBackRoute(
        onBack: () => context.go('/chapters'),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(child: Text('Capítulo no encontrado')),
        ),
      );
    }

    return HardwareBackRoute(
      onBack: () => context.go('/chapters'),
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Video Header ────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          color: context.firefly.cardSurface,
                          child: Center(
                            child: _videoError
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_off_rounded,
                                          color: context.colors.onSurface
                                              .withOpacity(0.6),
                                          size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No pudimos cargar el vídeo.\nRevisa tu conexión.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: context.colors.onSurface
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () {
                                          setState(() => _videoError = false);
                                          _initVideo();
                                        },
                                        child: const Text('Reintentar'),
                                      ),
                                    ],
                                  )
                                : CircularProgressIndicator(
                                    color: context.colors.primary,
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
                            gradient: context.firefly.primaryGradient,
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
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.onPrimary,
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
                              color: context.firefly.greenGlow,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '✓ Completado',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.colors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 16),

                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurface,
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    Text(
                      chapter.description,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        color: context.text.bodyMedium?.color,
                        height: 1.6,
                      ),
                    ).animate(delay: 150.ms).fadeIn(),

                    const SizedBox(height: 28),

                    // ── Facts ──────────────────────────────────────
                    if (chapter.facts.isNotEmpty) ...[
                      Text(
                        '💡 Datos curiosos',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.colors.onSurface,
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
                          color: context.firefly.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.firefly.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: context.colors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mira el video completo para desbloquear el siguiente nivel.',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  color: context.text.bodyMedium?.color,
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
        color: context.firefly.accentGlow,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: context.firefly.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.firefly.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fact,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: context.text.bodyMedium?.color,
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
