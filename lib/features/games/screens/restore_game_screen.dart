import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_catalog.dart';
import '../logic/game_audio.dart';
import '../models/game_id.dart';
import '../models/level_config.dart';
import '../providers/games_progress_provider.dart';
import '../theme/game_palette.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/level_outcome_overlay.dart';

/// "Restaurar el Bosque" — juego 5, el meta-juego. Ruta
/// `/game/restaurar/play/:level`, donde `level` es la zona (1..10).
///
/// El prototipo era un botón que gastaba puntos y perdía el progreso al
/// salir de la pantalla. Aquí cada zona es su propio "nivel": se paga con
/// **energía de luz** (ganada jugando los otros cuatro juegos, ver
/// `GamesProgressNotifier.recordResult`), queda persistida al despertarla
/// y el mapa completo vive en `RestoreMapScreen` — esta pantalla es el
/// close-up de una zona concreta, coherente con cómo entran los otros
/// niveles desde `LevelSelectScreen`.
class RestoreGameScreen extends ConsumerStatefulWidget {
  const RestoreGameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<RestoreGameScreen> createState() => _RestoreGameScreenState();
}

class _RestoreGameScreenState extends ConsumerState<RestoreGameScreen>
    with SingleTickerProviderStateMixin {
  late RestoreZone _zone;
  bool _restoring = false;
  GameResult? _result;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _zone = GameCatalog.level(GameId.restaurar, widget.level) as RestoreZone;
  }

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  Future<void> _restore(int energy) async {
    if (_restoring || energy < _zone.energyCost) return;
    setState(() => _restoring = true);
    GameAudio.instance.sfx(GameSfx.draw);
    await _grow.forward(from: 0);
    final ok = await ref
        .read(gamesProgressProvider.notifier)
        .lightZone(widget.level, _zone.energyCost);
    if (!mounted) return;
    GameAudio.instance.sfx(GameSfx.bloom);
    setState(() {
      _restoring = false;
      _result = GameResult(
        won: ok,
        stars: 3,
        detail: '${_zone.name} vuelve a brillar en el bosque.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final gamesState = ref.watch(gamesProgressProvider);
    final alreadyLit = gamesState.litZones.contains(widget.level);
    final canAfford = gamesState.energy >= _zone.energyCost;

    return GameScaffold(
      confirmExit: false,
      hud: GameHud(
        level: widget.level,
        title: _zone.name,
        trailing: [
          const Icon(Icons.bolt_rounded, size: 16, color: GameScene.lightTrail),
          const SizedBox(width: 4),
          Text(
            '${gamesState.energy}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: GameScene.onScene,
            ),
          ),
        ],
      ),
      overlay: _result != null
          ? LevelOutcomeOverlay(
              gameId: GameId.restaurar,
              level: widget.level,
              result: _result!,
              onRetry: () => setState(() => _result = null),
            )
          : null,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _grow,
              builder: (context, _) => CustomPaint(
                size: const Size(220, 220),
                painter: _ZonePainter(
                  progress: alreadyLit ? 1.0 : _grow.value,
                  t: _grow.value,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _zone.name,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: GameScene.onScene,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _zone.hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: GameScene.onSceneMuted,
              ),
            ),
            const SizedBox(height: 28),
            if (alreadyLit)
              const _StatusPill(
                icon: Icons.local_florist_rounded,
                text: 'Esta zona ya está viva.',
                color: GameScene.good,
              )
            else ...[
              _StatusPill(
                icon: Icons.bolt_rounded,
                text: 'Necesitas ${_zone.energyCost} de luz.',
                color: canAfford ? GameScene.lightTrail : GameScene.soft,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: canAfford && !_restoring
                    ? () => _restore(gamesState.energy)
                    : null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label:
                    Text(_restoring ? 'Despertando...' : 'Despertar zona'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                  backgroundColor: GameScene.home,
                  foregroundColor: Colors.black87,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
              if (!canAfford) ...[
                const SizedBox(height: 10),
                const Text(
                  'Consigue más luz jugando los otros retos del bosque.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: GameScene.onSceneMuted,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Árbol vectorial que "despierta": de tronco gris a follaje con glow, según
/// [progress]. Sustituye al `Opacity` sobre PNG del prototipo.
class _ZonePainter extends CustomPainter {
  const _ZonePainter({required this.progress, required this.t});

  final double progress;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final scale = size.shortestSide;

    // Tronco
    final trunk = Paint()..color = const Color(0xFF3D2B1F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + scale * 0.22),
          width: scale * 0.09,
          height: scale * 0.34,
        ),
        Radius.circular(scale * 0.02),
      ),
      trunk,
    );

    // Follaje base (apagado) siempre visible, para que se note el "antes".
    final dead = Paint()..color = const Color(0xFF394356);
    for (final o in [
      Offset(center.dx, center.dy - scale * 0.14),
      Offset(center.dx - scale * 0.16, center.dy + scale * 0.02),
      Offset(center.dx + scale * 0.16, center.dy + scale * 0.02),
    ]) {
      canvas.drawCircle(o, scale * 0.17, dead);
    }

    if (progress <= 0.02) return;

    final pulse = 0.85 + 0.15 * math.sin(t * 2 * math.pi * 3);
    final glow = Paint()
      ..color = GameScene.home.withValues(alpha: 0.22 * progress * pulse)
      ..maskFilter = null;
    canvas.drawCircle(center, scale * 0.34 * progress, glow);

    final live = Paint()..color = GameScene.home.withValues(alpha: progress);
    for (final o in [
      Offset(center.dx, center.dy - scale * 0.14),
      Offset(center.dx - scale * 0.16, center.dy + scale * 0.02),
      Offset(center.dx + scale * 0.16, center.dy + scale * 0.02),
    ]) {
      canvas.drawCircle(o, scale * 0.17 * progress.clamp(0.3, 1.0), live);
    }
  }

  @override
  bool shouldRepaint(_ZonePainter old) =>
      old.progress != progress || old.t != t;
}
