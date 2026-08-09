import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../logic/game_audio.dart';
import '../theme/game_palette.dart';

/// Marco común de las cinco pantallas de juego: cielo nocturno, partículas
/// de ambiente, HUD y — lo importante — **una sola** confirmación de salida.
///
/// Antes cada pantalla repetía su propio `PopScope` + `_onWillPop` con textos
/// ligeramente distintos. Aquí está una vez: salir a mitad de partida siempre
/// pregunta, y salir con la partida terminada nunca molesta.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.child,
    this.hud,
    this.overlay,
    this.confirmExit = true,
    this.onExit,
    this.exitRoute = '/game',
  });

  /// La escena del juego.
  final Widget child;

  /// Barra superior con nivel, vidas, energía. Va por encima de la escena.
  final Widget? hud;

  /// Capa por encima de todo (pausa, resumen de nivel).
  final Widget? overlay;

  /// Si `false`, el botón atrás sale sin preguntar (partida ya terminada).
  final bool confirmExit;

  /// Se llama justo antes de salir; sirve para pausar el motor.
  final VoidCallback? onExit;

  final String exitRoute;

  Future<bool> _confirm(BuildContext context) async {
    if (!confirmExit) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text('¿Dejar el bosque?', style: ctx.theme.textTheme.titleLarge),
        content: Text(
          'Si sales ahora perderás el avance de este nivel.',
          style: ctx.theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _exit(BuildContext context) async {
    if (!await _confirm(context)) return;
    onExit?.call();
    await GameAudio.instance.leaveGame();
    if (context.mounted) context.go(exitRoute);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit(context);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const SceneBackground(),
            SafeArea(
              bottom: true,
              child: Column(
                children: [
                  _GameTopBar(onExit: () => _exit(context), hud: hud),
                  Expanded(child: child),
                ],
              ),
            ),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

class _GameTopBar extends StatelessWidget {
  const _GameTopBar({required this.onExit, required this.hud});

  final VoidCallback onExit;
  final Widget? hud;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.arrow_back_rounded, color: GameScene.onScene),
            onPressed: onExit,
          ),
          if (hud != null) Expanded(child: hud!),
        ],
      ),
    );
  }
}

extension on BuildContext {
  ThemeData get theme => Theme.of(this);
}

/// Cielo nocturno con luciérnagas lejanas. Un único `AnimationController` y
/// un único `CustomPainter` para toda la escena, envuelto en
/// `RepaintBoundary` para que no arrastre al resto del árbol.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, this.particles = 22});

  final int particles;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final List<_Speck> _specks = List.generate(
    widget.particles,
    (i) => _Speck.forIndex(i),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: GameScene.skyGradient),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              painter: _SpeckPainter(_specks, _c.value),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.x,
    required this.y,
    required this.amp,
    required this.radius,
    required this.phase,
    required this.speed,
    required this.green,
  });

  final double x;
  final double y;
  final double amp;
  final double radius;
  final double phase;
  final double speed;
  final bool green;

  /// Determinista a partir del índice: dos escenas iguales se ven iguales y
  /// no hace falta guardar semillas ni un `Random` vivo.
  factory _Speck.forIndex(int i) {
    final r = math.Random(i * 7919);
    return _Speck(
      x: 0.05 + r.nextDouble() * 0.9,
      y: 0.05 + r.nextDouble() * 0.9,
      amp: 0.02 + r.nextDouble() * 0.05,
      radius: 0.8 + r.nextDouble() * 1.8,
      phase: r.nextDouble() * math.pi * 2,
      speed: 0.6 + r.nextDouble() * 1.8,
      green: i.isEven,
    );
  }
}

class _SpeckPainter extends CustomPainter {
  const _SpeckPainter(this.specks, this.t);

  final List<_Speck> specks;
  final double t;

  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 2 * math.pi;
    for (final s in specks) {
      final cx = (s.x + math.sin(time * s.speed * 0.3 + s.phase) * s.amp) *
          size.width;
      final cy = (s.y + math.cos(time * s.speed * 0.22 + s.phase) * s.amp) *
          size.height;
      final glow =
          (math.sin(time * s.speed * 3 + s.phase) + 1) / 2 * 0.7 + 0.15;
      final color = s.green ? GameScene.fireflyGreen : GameScene.firefly;
      _paint.color = color.withValues(alpha: 0.12 * glow);
      canvas.drawCircle(Offset(cx, cy), s.radius * 3.2, _paint);
      _paint.color = color.withValues(alpha: 0.75 * glow);
      canvas.drawCircle(Offset(cx, cy), s.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(_SpeckPainter old) => old.t != t;
}

/// Panel del HUD: nivel, y a la derecha lo que cada juego necesite (vidas,
/// energía, ronda). Se le pasa el contenido en vez de tener un campo por
/// cada cosa posible.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.level,
    required this.title,
    this.trailing = const [],
    this.progress,
  });

  final int level;
  final String title;
  final List<Widget> trailing;

  /// 0..1. Barra fina bajo el HUD (tiempo, ronda, energía).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GameScene.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GameScene.panelBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel $level',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: GameScene.onScene,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: GameScene.onSceneMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ...trailing,
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation(GameScene.lightTrail),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Contador de vidas del HUD: luciérnagas encendidas / apagadas.
class LifeDots extends StatelessWidget {
  const LifeDots({super.key, required this.alive, required this.total});

  final int alive;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        total,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.circle,
            size: 13,
            color: i < alive
                ? GameScene.firefly
                : GameScene.fireflyDim.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// Cartel de instrucciones que aparece al empezar el nivel y se va solo.
class LevelHintBanner extends StatelessWidget {
  const LevelHintBanner({super.key, required this.hint, required this.visible});

  final String hint;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Align(
          alignment: const Alignment(0, 0.62),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: GameScene.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GameScene.panelBorder),
            ),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: GameScene.onScene,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
