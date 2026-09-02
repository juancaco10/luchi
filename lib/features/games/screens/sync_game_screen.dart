import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../data/game_catalog.dart';
import '../logic/game_audio.dart';
import '../models/game_id.dart';
import '../models/level_config.dart';
import '../providers/games_progress_provider.dart';
import '../theme/game_palette.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/firefly_sprite_dot.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/level_outcome_overlay.dart';

/// Máquina de estados de "Sincronizar Luz". Explícita a propósito: el
/// prototipo usaba tres booleanos (`_isPlayingSequence`, y dos más
/// implícitos) que podían combinarse de formas no previstas. Con un enum
/// solo hay un estado a la vez y el `build` se lee como una tabla.
enum SyncState { idle, showing, input, success, fail }

/// "Sincronizar Luz" — juego 3 (tipo Simon). Ruta `/game/sincronizar/play/:level`.
///
/// Pura Flutter, sin Flame: es una máquina de estados sobre una cuadrícula
/// de luciérnagas, no una escena física.
class SyncGameScreen extends ConsumerStatefulWidget {
  const SyncGameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<SyncGameScreen> createState() => _SyncGameScreenState();
}

class _SyncGameScreenState extends ConsumerState<SyncGameScreen> {
  late SyncLevel _config;
  final _rnd = Random();

  SyncState _state = SyncState.idle;
  List<int> _sequence = [];
  int _round = 0;
  int _playerIndex = 0;
  int _activeNode = -1;
  int _fails = 0;
  GameResult? _result;
  bool _showHint = false;
  bool _countingDown = true;

  Timer? _idleHintTimer;
  Timer? _sequenceTimer;

  static const _maxFails = 6;
  static const _hintHideDelay = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _config = GameCatalog.level(GameId.sincronizar, widget.level) as SyncLevel;
    // El cartel de instrucciones solo aparece la primera vez que se inicia
    // el juego; en las siguientes partidas arranca directo la cuenta atrás.
    _showHint = LocalStorage.instance.isFirstGameStart('sincronizar');
    if (_showHint) {
      Future.delayed(_hintHideDelay, () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _idleHintTimer?.cancel();
    _sequenceTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _idleHintTimer?.cancel();
    _sequenceTimer?.cancel();
    setState(() {
      _sequence = List.generate(
        _config.startLength + _round,
        (_) => _rnd.nextInt(_config.nodes),
      );
      _playerIndex = 0;
      _state = SyncState.showing;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    for (var i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      setState(() => _activeNode = _sequence[i]);
      GameAudio.instance.sfx(GameSfx.tap);
      await Future.delayed(Duration(milliseconds: _config.showMs));
      if (!mounted) return;
      setState(() => _activeNode = -1);
      await Future.delayed(Duration(milliseconds: _config.gapMs));
    }
    if (!mounted) return;
    setState(() => _state = SyncState.input);
    _armHint();
  }

  /// Si el jugador se queda quieto 5s en modo entrada, repetimos la
  /// secuencia como pista — no cuenta como fallo.
  void _armHint() {
    _idleHintTimer?.cancel();
    _idleHintTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _state != SyncState.input) return;
      setState(() => _state = SyncState.showing);
      _playSequence();
    });
  }

  void _onTapNode(int node) {
    if (_state != SyncState.input) return;
    _idleHintTimer?.cancel();
    GameAudio.instance.sfx(GameSfx.tap);

    if (node != _sequence[_playerIndex]) {
      _onFail();
      return;
    }

    setState(() {
      _activeNode = node;
      _playerIndex++;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _activeNode = -1);
    });

    if (_playerIndex == _sequence.length) {
      _onRoundComplete();
    } else {
      _armHint();
    }
  }

  void _onRoundComplete() {
    GameAudio.instance.sfx(GameSfx.star);
    _round++;
    if (_round >= _config.rounds) {
      final stars = _fails == 0 ? 3 : (_fails <= 2 ? 2 : 1);
      setState(() {
        _state = SyncState.success;
        _result = GameResult(
          won: true,
          stars: stars,
          detail: _fails == 0
              ? 'Ni un solo fallo. ¡El bosque canta contigo!'
              : 'Completado con $_fails ${_fails == 1 ? "fallo" : "fallos"}.',
        );
      });
      return;
    }
    setState(() => _state = SyncState.idle);
    Future.delayed(const Duration(milliseconds: 500), _startRound);
  }

  void _onFail() {
    _fails++;
    GameAudio.instance.sfx(GameSfx.fail);
    setState(() => _state = SyncState.fail);
    if (_fails >= _maxFails) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _result = const GameResult.lost(
            detail: 'El patrón se te resiste. ¡Vuelve a intentarlo!',
          );
        });
      });
      return;
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _state = SyncState.idle);
      _startRound();
    });
  }

  void _retry() {
    _idleHintTimer?.cancel();
    _sequenceTimer?.cancel();
    setState(() {
      _state = SyncState.idle;
      _sequence = [];
      _round = 0;
      _playerIndex = 0;
      _fails = 0;
      _result = null;
      _showHint = false;
      _countingDown = true;
    });
  }

  static const _nodeColors = [
    GameScene.firefly,
    GameScene.fireflyGreen,
    Color(0xFFB388FF),
    Color(0xFF64D8FF),
    GameScene.firefly,
    GameScene.fireflyGreen,
    Color(0xFFB388FF),
    Color(0xFF64D8FF),
  ];

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      confirmExit: _result == null,
      hud: GameHud(
        level: widget.level,
        title: 'Sincronizar Luz',
        progress: _config.rounds == 0 ? null : _round / _config.rounds,
        trailing: [
          const Icon(Icons.star_rounded, size: 16, color: GameScene.firefly),
          const SizedBox(width: 4),
          Text(
            '$_round/${_config.rounds}',
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
              gameId: GameId.sincronizar,
              level: widget.level,
              result: _result!,
              onRetry: _retry,
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: _NodeRing(
              count: _config.nodes,
              activeNode: _activeNode,
              failing: _state == SyncState.fail,
              enabled: _state == SyncState.input,
              colors: _nodeColors,
              onTap: _onTapNode,
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.6),
            child: _StateBanner(state: _state),
          ),
          LevelHintBanner(hint: _config.hint, visible: _showHint),
          if (_countingDown)
            CountdownOverlay(
              onFinished: () {
                if (!mounted) return;
                setState(() {
                  _countingDown = false;
                  _showHint = false;
                });
                _startRound();
              },
            ),
        ],
      ),
    );
  }
}

class _StateBanner extends StatelessWidget {
  const _StateBanner({required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      SyncState.idle => '',
      SyncState.showing => 'Mira con atención...',
      SyncState.input => 'Ahora tú: repite el patrón',
      SyncState.success => '¡Muy bien!',
      SyncState.fail => 'Casi... ¡de nuevo!',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GameScene.panel,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: state == SyncState.fail
                ? GameScene.soft
                : GameScene.onScene,
          ),
        ),
      ),
    );
  }
}

class _NodeRing extends StatelessWidget {
  const _NodeRing({
    required this.count,
    required this.activeNode,
    required this.failing,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final int count;
  final int activeNode;
  final bool failing;
  final bool enabled;
  final List<Color> colors;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight) * 0.78;
        final radius = side / 2 - 40;
        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(count, (i) {
              final angle = -pi / 2 + (2 * pi / count) * i;
              final dx = radius * cos(angle);
              final dy = radius * sin(angle);
              final lit = i == activeNode;
              return Transform.translate(
                offset: Offset(dx, dy),
                child: _SyncNode(
                  color: colors[i % colors.length],
                  lit: lit,
                  shake: failing && lit,
                  enabled: enabled,
                  onTap: () => onTap(i),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _SyncNode extends StatelessWidget {
  const _SyncNode({
    required this.color,
    required this.lit,
    required this.shake,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final bool lit;
  final bool shake;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Los nodos están en un anillo (coordenadas polares, ver el
    // `Transform.translate` de más arriba), así que la travesía
    // direccional de foco por defecto no sigue el círculo — pero sí
    // permite alcanzar cada nodo con Tab/D-pad en el orden en que se
    // generan, que es preferible a que queden completamente
    // inalcanzables como GestureDetector.
    return FocusableActionDetector(
      enabled: enabled,
      actions: {
        ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
          if (enabled) onTap();
          return null;
        }),
      },
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedScale(
          scale: lit ? 1.25 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: FireflySpriteDot(
            size: 46,
            color: color,
            lit: lit,
            // Apagados quedan quietos; cuando el bosque los llama (secuencia
            // o acierto) parpadean y baten las alas.
            animate: lit,
          ),
        ),
      ),
    );
  }
}
