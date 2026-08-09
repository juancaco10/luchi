import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/game_catalog.dart';
import '../logic/guiar_luciernagas_game.dart';
import '../models/game_id.dart';
import '../models/level_config.dart';
import '../providers/games_progress_provider.dart';
import '../theme/game_palette.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/level_outcome_overlay.dart';
import '../../../core/storage/local_storage.dart';

/// "Guiar Luciérnagas" — juego 2. Ruta `/game/guiar/play/:level`.
class GuideGameScreen extends ConsumerStatefulWidget {
  const GuideGameScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<GuideGameScreen> createState() => _GuideGameScreenState();
}

class _GuideGameScreenState extends ConsumerState<GuideGameScreen> {
  late GuideLevel _config;
  GuiarLuciernagasGame? _game;
  GameResult? _result;
  bool _showHint = false;
  bool _countingDown = true;
  Timer? _hudTick;

  static const _hintHideDelay = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _config = GameCatalog.level(GameId.guiar, widget.level) as GuideLevel;
    // El cartel de instrucciones solo aparece la primera vez que se inicia
    // el juego; en las siguientes partidas arranca directo la cuenta atrás.
    _showHint = LocalStorage.instance.isFirstGameStart('guiar');
    _startGame();
    if (_showHint) {
      Future.delayed(_hintHideDelay, () {
        if (mounted) setState(() => _showHint = false);
      });
    }
  }

  @override
  void dispose() {
    _hudTick?.cancel();
    super.dispose();
  }

  void _startGame() {
    _game = GuiarLuciernagasGame(
      config: _config,
      onGameFinished: (r) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _result = GameResult(
              won: r.won,
              stars: r.stars,
              detail: '${r.saved} de ${r.total} llegaron a casa.',
            );
          });
        });
      },
    );
    // El HUD (barra de energía, contador de luciérnagas) se refresca por
    // temporizador, no desde `update()` del juego: llamar `setState` en
    // cada frame del motor (60/s) podía coincidir con el propio ciclo de
    // build de Flutter y disparar "setState() called during build".
    _hudTick?.cancel();
    _hudTick = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted && _result == null) setState(() {});
    });
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
    final saved = _game?.savedCount ?? 0;
    return GameScaffold(
      confirmExit: _result == null,
      hud: GameHud(
        level: widget.level,
        title: 'Guiar Luciérnagas',
        progress: _game?.energyFraction,
        trailing: [
          const Icon(Icons.bolt_rounded, size: 16, color: GameScene.lightTrail),
          const SizedBox(width: 4),
          Text(
            '$saved/${_config.fireflies}',
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
              gameId: GameId.guiar,
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
                if (mounted) setState(() => _countingDown = false);
              },
            ),
        ],
      ),
    );
  }
}
