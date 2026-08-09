import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../data/game_catalog.dart';
import '../logic/proteger_luz_game.dart';
import '../models/game_id.dart';
import '../models/level_config.dart';
import '../providers/games_progress_provider.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/level_outcome_overlay.dart';

/// "Proteger la Luz" — juego 4. Ruta `/game/proteger/play/:level`.
class ProtectGameScreen extends ConsumerStatefulWidget {
  const ProtectGameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<ProtectGameScreen> createState() => _ProtectGameScreenState();
}

class _ProtectGameScreenState extends ConsumerState<ProtectGameScreen> {
  late ProtectLevel _config;
  ProtegerLuzGame? _game;
  int _lives = 0;
  int _total = 0;
  GameResult? _result;
  bool _showHint = false;
  bool _countingDown = true;
  Timer? _tick;

  static const _hintHideDelay = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _config = GameCatalog.level(GameId.proteger, widget.level) as ProtectLevel;
    // El cartel de instrucciones solo aparece la primera vez que se inicia
    // el juego; en las siguientes partidas arranca directo la cuenta atrás.
    _showHint = LocalStorage.instance.isFirstGameStart('proteger');
    if (_showHint) {
      Future.delayed(_hintHideDelay, () {
        if (mounted) setState(() => _showHint = false);
      });
    }
    _startGame();
    // Refresca la barra de tiempo del HUD; el motor no notifica por sí solo.
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted && _result == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _startGame() {
    _lives = _config.fireflies;
    _total = _config.fireflies;
    _game = ProtegerLuzGame(
      config: _config,
      onLivesChanged: (alive, total) {
        if (!mounted) return;
        setState(() {
          _lives = alive;
          _total = total;
        });
      },
      onGameFinished: (r) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _result = GameResult(
              won: r.won,
              stars: r.stars,
              detail: r.won
                  ? '${r.alive} de ${r.total} luciérnagas a salvo.'
                  : 'Se apagaron todas. ¡El bosque te espera de nuevo!',
            );
          });
        });
      },
    )..enginePaused = true;
  }

  void _retry() {
    setState(() {
      _result = null;
      _showHint = false;
      _countingDown = true;
    });
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      confirmExit: _result == null,
      hud: GameHud(
        level: widget.level,
        title: 'Proteger la Luz',
        progress: _game?.timeFraction,
        trailing: [LifeDots(alive: _lives, total: _total)],
      ),
      overlay: _result != null
          ? LevelOutcomeOverlay(
              gameId: GameId.proteger,
              level: widget.level,
              result: _result!,
              onRetry: _retry,
            )
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game!, key: ValueKey(_game)),
          LevelHintBanner(hint: _config.hint, visible: _showHint),
          if (_countingDown)
            CountdownOverlay(
              onFinished: () {
                if (!mounted) return;
                setState(() {
                  _countingDown = false;
                  _showHint = false;
                });
                _game?.enginePaused = false;
              },
            ),
        ],
      ),
    );
  }
}
