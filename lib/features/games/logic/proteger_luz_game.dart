import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Colors;

import '../models/level_config.dart';
import '../theme/game_palette.dart';
import 'firefly_sprite.dart';
import 'game_audio.dart';

/// Motor de "Proteger la Luz".
///
/// Reescrito para respetar "no violencia" de verdad: nada se destruye ni
/// recibe daño de forma permanente. Una amenaza que toca a una luciérnaga
/// sin escudo la **apaga** (se puede reavivar tocándola en los 3 segundos
/// siguientes); solo si nadie la reaviva a tiempo cuenta como perdida.
/// El escudo ya no tiene un radio fijo de 40px (se rompía en tablets): es
/// proporcional al ancho de pantalla.
class ProtegerLuzGame extends FlameGame with PanDetector, MultiTouchTapDetector {
  ProtegerLuzGame({
    required this.config,
    required this.onGameFinished,
    required this.onLivesChanged,
  });

  final ProtectLevel config;
  final void Function(ProtectGameResult result) onGameFinished;
  final void Function(int lives, int total) onLivesChanged;

  late ShieldComponent _shield;
  final List<FireflyVulnerable> _fireflies = [];
  final List<ThreatComponent> _threats = [];

  bool _isPlaying = true;
  double _timeSurvived = 0;
  double _spawnTimer = 0;
  int _permanentlyLost = 0;
  final _rnd = math.Random();

  /// Pausa el motor (cuenta atrás inicial, por ejemplo): la escena sigue
  /// animándose (las luciérnagas baten las alas) pero nada avanza ni puede
  /// salir mal. No se usa `FlameGame.paused` porque ese congela también la
  /// animación de los sprites.
  bool enginePaused = false;

  late final SpriteAnimation fireflyAnimation;

  int get livesAlive => _fireflies.length - _permanentlyLost;
  double get timeFraction =>
      config.durationSeconds <= 0 ? 0 : (_timeSurvived / config.durationSeconds).clamp(0.0, 1.0);

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final sheetImage = await images.load('games/firefly_spritesheet.jpg');
    fireflyAnimation = FireflySprite.animation(sheetImage);
    _setupLevel();
  }

  void _setupLevel() {
    _isPlaying = true;
    _timeSurvived = 0;
    _spawnTimer = 0;
    _permanentlyLost = 0;
    removeAll(children.toList());
    _fireflies.clear();
    _threats.clear();

    for (var i = 0; i < config.fireflies; i++) {
      final firefly = FireflyVulnerable(
        basePosition: Vector2(
          size.x * 0.22 + _rnd.nextDouble() * size.x * 0.56,
          size.y * 0.58 + _rnd.nextDouble() * size.y * 0.28,
        ),
        animation: fireflyAnimation,
        pulsePhase: _rnd.nextDouble() * 6.28,
        onLost: () {
          _permanentlyLost++;
          onLivesChanged(livesAlive, config.fireflies);
          GameAudio.instance.sfx(GameSfx.fail);
          if (livesAlive <= 0) _finish(false);
        },
      );
      _fireflies.add(firefly);
      add(firefly);
    }

    _shield = ShieldComponent(
      position: Vector2(size.x / 2, size.y / 2),
      radius: size.x * 0.10,
    );
    add(_shield);
    onLivesChanged(livesAlive, config.fireflies);
  }

  void resetGame() => _setupLevel();

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!_isPlaying) return;
    _shield.position += info.delta.global;
    _shield.position.x =
        _shield.position.x.clamp(_shield.radius, size.x - _shield.radius);
    _shield.position.y =
        _shield.position.y.clamp(_shield.radius, size.y - _shield.radius);
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    if (!_isPlaying) return;
    // Tocar una luciérnaga apagada (pero no perdida) la reaviva.
    for (final f in _fireflies) {
      if (f.isDimmed &&
          f.position.distanceTo(info.eventPosition.global) < f.radius * 2.4) {
        f.revive();
        GameAudio.instance.sfx(GameSfx.bloom);
        break;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (enginePaused || !_isPlaying) return;

    for (final f in _fireflies) {
      f.tick(dt);
    }

    _timeSurvived += dt;
    if (_timeSurvived >= config.durationSeconds) {
      _finish(true);
      return;
    }

    final spawnEvery = _lerpSpawn();
    _spawnTimer += dt;
    if (_spawnTimer > spawnEvery) {
      _spawnTimer = 0;
      _spawnThreat();
    }

    for (var i = _threats.length - 1; i >= 0; i--) {
      final threat = _threats[i];
      threat.tick(dt);

      final dShield = threat.position.distanceTo(_shield.position);
      if (dShield < threat.radius + _shield.radius) {
        GameAudio.instance.sfx(GameSfx.shield);
        _shield.pulse();
        if (threat.kind == ThreatKind.gota) {
          threat.velocity.y = -threat.velocity.y * 0.8;
          threat.velocity.x += (threat.position.x - _shield.position.x) * 2;
        } else {
          threat.removeFromParent();
          _threats.removeAt(i);
        }
        continue;
      }

      for (final firefly in _fireflies) {
        if (firefly.isLit &&
            threat.position.distanceTo(firefly.position) <
                threat.radius + firefly.radius) {
          firefly.dim();
          threat.removeFromParent();
          _threats.removeAt(i);
          break;
        }
      }

      if (i < _threats.length &&
          (threat.position.y > size.y + threat.radius * 2 ||
              threat.position.y < -size.y)) {
        threat.removeFromParent();
        _threats.remove(threat);
      }
    }
  }

  double _lerpSpawn() {
    final t = timeFraction;
    return config.spawnStart + (config.spawnEnd - config.spawnStart) * t;
  }

  void _spawnThreat() {
    final kind = config.threats[_rnd.nextInt(config.threats.length)];
    final startX = _rnd.nextDouble() * size.x;
    final speed = config.fallSpeed * size.y * (0.85 + _rnd.nextDouble() * 0.3);
    final threat = ThreatComponent(
      kind: kind,
      position: Vector2(startX, -30),
      velocity: Vector2((_rnd.nextDouble() - 0.5) * size.x * 0.25, speed),
    );
    _threats.add(threat);
    add(threat);
  }

  void _finish(bool won) {
    if (!_isPlaying) return;
    _isPlaying = false;
    final total = config.fireflies;
    final alive = livesAlive;
    final stars = !won
        ? 0
        : alive == total
            ? 3
            : (alive >= (total / 2).ceil() ? 2 : 1);
    onGameFinished(ProtectGameResult(
      won: won,
      stars: stars,
      alive: alive,
      total: total,
    ));
  }
}

class ProtectGameResult {
  const ProtectGameResult({
    required this.won,
    required this.stars,
    required this.alive,
    required this.total,
  });

  final bool won;
  final int stars;
  final int alive;
  final int total;
}

// ── Componentes ───────────────────────────────────────────────────

class ShieldComponent extends PositionComponent {
  ShieldComponent({required Vector2 position, required this.radius}) {
    this.position = position;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  final double radius;
  double _pulseT = 0;

  void pulse() => _pulseT = 1;

  static final Paint _glow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  static final Paint _fill = Paint();
  static final Paint _border = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  @override
  void update(double dt) {
    super.update(dt);
    if (_pulseT > 0) _pulseT = (_pulseT - dt * 3).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final extra = 1 + _pulseT * 0.18;

    _glow.color = GameScene.shield.withValues(alpha: 0.28);
    canvas.drawCircle(center, radius * extra, _glow);

    _fill.color = GameScene.shield.withValues(alpha: 0.16);
    canvas.drawCircle(center, radius * extra, _fill);

    _border.color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius * extra, _border);
  }
}

class ThreatComponent extends PositionComponent {
  ThreatComponent({
    required this.kind,
    required Vector2 position,
    required this.velocity,
  }) : radius = kind == ThreatKind.nube ? 30 : (kind == ThreatKind.sombra ? 16 : 13) {
    this.position = position;
    anchor = Anchor.center;
  }

  final ThreatKind kind;
  final double radius;
  Vector2 velocity;
  double _t = 0;

  void tick(double dt) {
    _t += dt;
    switch (kind) {
      case ThreatKind.gota:
        velocity.y += 60 * dt;
        position += velocity * dt;
      case ThreatKind.sombra:
        position += velocity * dt;
        position.x += math.sin(_t * 5) * 90 * dt;
      case ThreatKind.nube:
        velocity.y += 20 * dt;
        position += velocity * dt;
    }
  }

  static final Paint _fill = Paint();
  static final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    switch (kind) {
      case ThreatKind.gota:
        _fill.color = GameScene.rain.withValues(alpha: 0.9);
        final path = Path()
          ..moveTo(0, -radius)
          ..quadraticBezierTo(radius, radius * 0.2, 0, radius)
          ..quadraticBezierTo(-radius, radius * 0.2, 0, -radius);
        canvas.drawPath(path, _fill);
      case ThreatKind.sombra:
        _fill.color = GameScene.shadow.withValues(alpha: 0.8);
        canvas.drawCircle(Offset.zero, radius, _fill);
        _stroke
          ..color = Colors.black.withValues(alpha: 0.4)
          ..strokeWidth = 2;
        canvas.drawCircle(Offset.zero, radius, _stroke);
      case ThreatKind.nube:
        _fill.color = GameScene.cloud.withValues(alpha: 0.75);
        for (final o in const [
          Offset(-10, 2),
          Offset(10, 2),
          Offset(0, -6),
        ]) {
          canvas.drawCircle(o, radius * 0.62, _fill);
        }
    }
  }
}

/// Luciérnaga a proteger. Tres estados: encendida, apagada-reavivable
/// (ventana de 3s) y perdida (no cuenta hasta que se reinicia el nivel).
///
/// Usa el mismo sprite y luz de cola que Guiar (`FireflySpriteComponent`):
/// es la mascota del producto, idéntica en los dos juegos Flame. El sprite
/// mide 36×34 como allí, pero el radio de colisión se queda en 12 (el que
/// tenía el arte vectorial) para no cambiar el balance de los niveles.
class FireflyVulnerable extends FireflySpriteComponent {
  FireflyVulnerable({
    required this.basePosition,
    required this.onLost,
    required super.animation,
    super.pulsePhase,
  }) : super(
          position: basePosition,
          size: Vector2(36, 34),
          radius: 12,
        );

  final Vector2 basePosition;
  final void Function() onLost;

  double? _reviveDeadline;
  bool _lost = false;

  bool get isLit => !_lost && _reviveDeadline == null;
  bool get isDimmed => !_lost && _reviveDeadline != null;

  void dim() {
    if (_lost || _reviveDeadline != null) return;
    _reviveDeadline = 3.0;
    dimmed = true;
  }

  void revive() {
    _reviveDeadline = null;
    dimmed = false;
  }

  /// Avanza el vaivén y el temporizador de reavivado. La posición base es
  /// fija; el `animT` del sprite (fase, parpadeo) lo mueve el propio update.
  void tick(double dt) {
    position = basePosition +
        Vector2(math.sin(animT * 1.6) * 18, math.cos(animT * 1.2) * 10);

    if (_reviveDeadline != null) {
      _reviveDeadline = _reviveDeadline! - dt;
      if (_reviveDeadline! <= 0) {
        _reviveDeadline = null;
        _lost = true;
        visible = false;
        onLost();
      }
    }
  }

  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..color = GameScene.soft.withValues(alpha: 0.8);

  @override
  void render(Canvas canvas) {
    if (_lost) return;
    super.render(canvas);
    // Aro de progreso sobre la luciérnaga apagada: la cuenta hacia atrás
    // que le queda para reavivarla.
    if (_reviveDeadline != null) {
      final progress = (_reviveDeadline! / 3.0).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.x / 2, size.y / 2),
          radius: size.x * 0.42,
        ),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        _ringPaint,
      );
    }
  }
}
