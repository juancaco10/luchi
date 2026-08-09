import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/constants.dart';
import '../data/game_catalog.dart';
import '../logic/game_audio.dart';
import '../models/game_id.dart';
import '../providers/games_progress_provider.dart';
import '../theme/game_palette.dart';
import 'star_row.dart';

/// Pantalla de fin de nivel, común a los cuatro juegos jugables.
///
/// Es también **el único sitio que acredita el resultado**: registra las
/// estrellas y paga puntos/energía al montarse, una sola vez. Antes cada
/// juego llamaba a `addPoints` por su cuenta con cantidades distintas (o no
/// llamaba en absoluto), y por eso dos de los cinco no daban nada.
class LevelOutcomeOverlay extends ConsumerStatefulWidget {
  const LevelOutcomeOverlay({
    super.key,
    required this.gameId,
    required this.level,
    required this.result,
    required this.onRetry,
  });

  final GameId gameId;
  final int level;
  final GameResult result;

  /// Reinicia el nivel sin recrear la pantalla.
  final VoidCallback onRetry;

  @override
  ConsumerState<LevelOutcomeOverlay> createState() =>
      _LevelOutcomeOverlayState();
}

class _LevelOutcomeOverlayState extends ConsumerState<LevelOutcomeOverlay> {
  GameReward? _reward;

  @override
  void initState() {
    super.initState();
    // `recordResult` muta el provider de forma síncrona; hacerlo aquí, en
    // plena fase de build, dispara el assert de Riverpod ("modifying a
    // provider while the widget tree was building") en debug y la pantalla
    // se cae justo al ganar. Se difiere al final del frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _credit());
  }

  Future<void> _credit() async {
    final reward = await ref
        .read(gamesProgressProvider.notifier)
        .recordResult(widget.gameId, widget.level, widget.result);
    GameAudio.instance.sfx(widget.result.won ? GameSfx.win : GameSfx.lose);
    if (mounted) setState(() => _reward = reward);
  }

  bool get _hasNext => widget.level < AppConstants.levelsPerGame;

  void _goNext() {
    context.pushReplacement(
      '/game/${widget.gameId.slug}/play/${widget.level + 1}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.result.won;
    final reward = _reward;
    final info = GameCatalog.info(widget.gameId);

    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: GameScene.panel,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: info.accent.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: info.accent.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '¡Nivel superado!' : 'Casi lo tienes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: won ? GameScene.good : GameScene.soft,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.result.detail ??
                    (won
                        ? 'El bosque brilla un poco más.'
                        : 'Inténtalo otra vez, guardián.'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: GameScene.onSceneMuted,
                ),
              ),
              const SizedBox(height: 20),
              StarRow(stars: widget.result.stars, size: 44, animate: won),
              const SizedBox(height: 20),

              // Recompensa. Mientras se guarda no se muestra nada — tarda
              // milisegundos y un esqueleto parpadeando sería peor.
              if (reward != null) _RewardLines(reward: reward),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GameScene.onScene,
                        side: const BorderSide(color: GameScene.panelBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      label: const Text('Reintentar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: won && _hasNext
                          ? _goNext
                          : () => context.go('/game/${widget.gameId.slug}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: info.accent,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        won && _hasNext
                            ? Icons.arrow_forward_rounded
                            : Icons.map_rounded,
                        size: 18,
                      ),
                      label: Text(won && _hasNext ? 'Siguiente' : 'Niveles'),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () =>
                        context.go('/game/${widget.gameId.slug}'),
                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                    style: TextButton.styleFrom(
                      foregroundColor: GameScene.onSceneMuted,
                    ),
                    label: const Text('Selector de niveles'),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/game'),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    style: TextButton.styleFrom(
                      foregroundColor: GameScene.onSceneMuted,
                    ),
                    label: const Text('Menú de juegos'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardLines extends StatelessWidget {
  const _RewardLines({required this.reward});

  final GameReward reward;

  @override
  Widget build(BuildContext context) {
    if (reward.isEmpty) {
      return const Text(
        'Ya tenías esta marca. ¡Supérala para ganar más luz!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          color: GameScene.onSceneMuted,
        ),
      );
    }

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            if (reward.points > 0)
              _Chip(
                icon: Icons.local_fire_department_rounded,
                label: '+${reward.points} puntos',
                color: GameScene.firefly,
              ),
            if (reward.energy > 0)
              _Chip(
                icon: Icons.bolt_rounded,
                label: '+${reward.energy} de luz',
                color: GameScene.lightTrail,
              ),
          ],
        ),
        if (reward.dailyBonus) ...[
          const SizedBox(height: 10),
          const Text(
            '¡Primera partida del día! Bonus de luz incluido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GameScene.good,
            ),
          ),
        ],
        if (reward.unlockedNextGame != null) ...[
          const SizedBox(height: 10),
          Text(
            '¡Has desbloqueado "${GameCatalog.info(reward.unlockedNextGame!).title}"!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: GameScene.lightTrail,
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
