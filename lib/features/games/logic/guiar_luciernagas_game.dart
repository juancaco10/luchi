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

/// Motor de "Guiar Luciérnagas".
///
/// Reescrito desde cero sobre la idea original (boids `seek`/`separate`,
/// que funcionaba bien), pero corrige tres cosas del prototipo:
///
/// 1. **Nada muere.** El prototipo mataba luciérnagas al tocar cualquier
///    obstáculo, lo que contradice "no violencia" del brief. Ahora una roca
///    empuja, el agua aturde un momento y la sombra frena — todo reversible.
/// 2. **Recurso en vez de reloj**: no hay temporizador, solo una energía de
///    luz que se gasta al dibujar. Un niño puede pararse a pensar sin que
///    el juego lo penalice por tardar.
/// 3. **Seguimiento por punto adelantado**: cada luciérnaga busca el punto
///    del camino más cercano a ella y avanza unos pasos por delante, no el
///    último punto dibujado — así no se agolpan todas en el dedo del
///    jugador.
class GuiarLuciernagasGame extends FlameGame with PanDetector {
  GuiarLuciernagasGame({
    required this.config,
    required this.onGameFinished,
  });

  final GuideLevel config;
  final void Function(GuideGameResult result) onGameFinished;

  late HomeComponent _home;
  final List<_Obstacle> _obstacles = [];
  final List<FireflyGuideComponent> _fireflies = [];
  late _TrailComponent _trail;

  late final SpriteAnimation fireflyAnimation;  double energy = 0;
  double get energyFraction =>
      config.energy <= 0 ? 0 : (energy / config.energy).clamp(0.0, 1.0);

  int get savedCount => _fireflies.where((f) => f.arrived).length;
  int get totalFireflies => _fireflies.length;

  bool _finished = false;
  double _settledFor = 0;
  static const _settleGrace = 1.6;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    energy = config.energy;

    final bgImage = await images.load('games/guiar_luciernagas_bg.jpg');
    add(_BlurredBackground(image: bgImage, screenSize: size));

    final sheetImage = await images.load('games/firefly_spritesheet.jpg');
    fireflyAnimation = FireflySprite.animation(sheetImage);

    // El arte real de cada frame es ancho (alas desplegadas) con márgenes
    // negros: se respeta la proporción de la celda con un ligero sesgo
    // vertical para darles presencia.
    final fireflySize = Vector2(36, 34);

    _home = HomeComponent(
      position: Vector2(
        size.x * config.homeX,
        math.max(size.y * config.homeY, HomeComponent.glowRadius + 8),
      ),
    );
    add(_home);

    _obstacles
      ..clear()
      ..addAll(config.obstacles.map((spec) => _Obstacle(spec, size)));
    for (final o in _obstacles) {
      add(o);
    }

    _trail = _TrailComponent();
    add(_trail);

    _fireflies.clear();
    final spread = math.min(size.x * 0.6, config.fireflies * 34.0);
    for (var i = 0; i < config.fireflies; i++) {
      final offset =
          (i - (config.fireflies - 1) / 2) * (spread / math.max(1, config.fireflies - 1));
      final firefly = FireflyGuideComponent(
        position: Vector2(
          size.x / 2 + offset,
          math.min(size.y * config.startY, size.y - 24),
        ),
        home: _home,
        animation: fireflyAnimation,
        size: fireflySize,
      );
      _fireflies.add(firefly);
      add(firefly);
    }
  }

  void resetGame() {
    _finished = false;
    _settledFor = 0;
    removeAll(children.toList());
    onLoad();
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (_finished || energy <= 0) return;
    // `widget` = coordenadas relativas al GameWidget (el lienzo del juego).
    // `global` sería relativo a toda la pantalla y desplazaría el rastro
    // respecto al dedo (barra superior + status bar).
    _trail.addPoint(info.eventPosition.widget);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_finished || energy <= 0) return;
    final added = _trail.addPoint(info.eventPosition.widget);
    if (added > 0) {
      energy = math.max(0, energy - added);
      if (energy <= 0) GameAudio.instance.sfx(GameSfx.tap);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;

    for (final o in _obstacles) {
      o.tick(dt, size);
    }

    var saved = 0;
    var settledAll = true;
    for (final firefly in _fireflies) {
      firefly.stepPhysics(dt);

      if (!firefly.arrived) {
        settledAll = false;

        // Objetivo: un punto del camino por delante de la luciérnaga, o el
        // hogar directamente si ya está muy cerca / no queda camino.
        final target = _trail.pointAhead(firefly.position, lookAhead: 5) ??
            (firefly.position.distanceTo(_home.position) < 160
                ? _home.position
                : null);
        if (target != null) firefly.seek(target);
        firefly.separate(_fireflies);

        for (final o in _obstacles) {
          o.interact(firefly);
        }

        if (firefly.position.distanceTo(_home.position) <
            _home.radius + firefly.radius) {
          firefly.arrived = true;
          GameAudio.instance.sfx(GameSfx.arrive);
        }
      } else {
        saved++;
      }
    }

    // El nivel se resuelve cuando todas llegaron, o cuando ya no queda ni
    // energía ni camino dibujado y les damos un margen para que las que
    // estén en vuelo terminen de llegar.
    final canStillGuide = energy > 0 || _trail.hasPoints;
    if (saved == _fireflies.length) {
      _finish(saved);
    } else if (!canStillGuide) {
      _settledFor += dt;
      if (settledAll || _settledFor > _settleGrace) {
        _finish(saved);
      }
    } else {
      _settledFor = 0;
    }
  }

  void _finish(int saved) {
    if (_finished) return;
    _finished = true;
    final total = _fireflies.length;
    final won = saved >= config.required_;
    final stars = !won
        ? 0
        : saved == total
            ? 3
            : (saved > config.required_ ? 2 : 1);
    onGameFinished(GuideGameResult(
      won: won,
      stars: stars,
      saved: saved,
      total: total,
    ));
  }
}

class GuideGameResult {
  const GuideGameResult({
    required this.won,
    required this.stars,
    required this.saved,
    required this.total,
  });

  final bool won;
  final int stars;
  final int saved;
  final int total;
}

// ── Componentes ───────────────────────────────────────────────────

class HomeComponent extends PositionComponent {
  static const double baseRadius = 46;
  static const double glowRadius = baseRadius * 1.5;

  HomeComponent({required super.position})
      : radius = baseRadius,
        super(anchor: Anchor.center, size: Vector2.all(baseRadius * 2));

  final double radius;
  double _t = 0;

  static final Paint _glow = Paint();
  static final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  static final Paint _core = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.75 + 0.25 * math.sin(_t * 1.6);
    final center = Offset(radius, radius);

    _glow.color = GameScene.home.withValues(alpha: 0.20 * pulse);
    canvas.drawCircle(center, radius * 1.5, _glow);
    _glow.color = GameScene.home.withValues(alpha: 0.32 * pulse);
    canvas.drawCircle(center, radius * 1.05, _glow);

    _core.color = GameScene.home.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius * 0.8, _core);

    _ring.color = GameScene.home.withValues(alpha: 0.9);
    canvas.drawCircle(center, radius * 0.8, _ring);

    // Silueta de árbol simple, vectorial.
    final trunk = Paint()..color = const Color(0xFF3D2B1F);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(center.dx, center.dy + radius * 0.32),
            width: radius * 0.22,
            height: radius * 0.6),
        const Radius.circular(4),
      ),
      trunk,
    );
    final foliage = Paint()..color = GameScene.home.withValues(alpha: 0.85);
    for (final o in [
      Offset(center.dx, center.dy - radius * 0.28),
      Offset(center.dx - radius * 0.32, center.dy - radius * 0.02),
      Offset(center.dx + radius * 0.32, center.dy - radius * 0.02),
    ]) {
      canvas.drawCircle(o, radius * 0.34, foliage);
    }
  }
}

class _Obstacle extends PositionComponent {
  _Obstacle(this.spec, Vector2 screenSize)
      : basePosition = Vector2(spec.x * screenSize.x, spec.y * screenSize.y),
        radiusPx = spec.radius * screenSize.x,
        super(
          position: Vector2(spec.x * screenSize.x, spec.y * screenSize.y),
          anchor: Anchor.center,
        );

  final ObstacleSpec spec;
  final Vector2 basePosition;
  final double radiusPx;
  double _t = 0;

  static final Paint _fill = Paint();
  static final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  void tick(double dt, Vector2 screenSize) {
    _t += dt;
    if (spec.driftX != 0) {
      final dx = math.sin(_t * spec.driftX * 2 * math.pi) *
          spec.driftRange *
          screenSize.x;
      position = Vector2(basePosition.x + dx, basePosition.y);
    }
  }

  /// Efecto sobre una luciérnaga que la toca. Nada es letal: cada tipo tiene
  /// una consecuencia temporal y reversible.
  void interact(FireflyGuideComponent firefly) {
    final d = position.distanceTo(firefly.position);
    final touchRadius = radiusPx + firefly.radius;
    if (d >= touchRadius) return;

    switch (spec.kind) {
      case ObstacleKind.roca:
        final normal = (firefly.position - position) / (d == 0 ? 1 : d);
        firefly.position = position + normal * (touchRadius + 1);
        firefly.velocity = normal * (firefly.velocity.length * 0.5 + 20);
      case ObstacleKind.agua:
        firefly.daze(1.6);
      case ObstacleKind.sombra:
        firefly.slowFor(0.35);
    }
  }

  @override
  void render(Canvas canvas) {
    switch (spec.kind) {
      case ObstacleKind.roca:
        _fill.color = GameScene.rock;
        canvas.drawCircle(Offset.zero, radiusPx, _fill);
        _stroke
          ..color = GameScene.rockEdge
          ..strokeWidth = 3;
        canvas.drawCircle(Offset.zero, radiusPx, _stroke);
      case ObstacleKind.agua:
        final wobble = 1 + 0.05 * math.sin(_t * 2.4);
        _fill.color = GameScene.water.withValues(alpha: 0.75);
        canvas.drawCircle(Offset.zero, radiusPx * wobble, _fill);
        _fill.color = Colors.white.withValues(alpha: 0.12);
        canvas.drawCircle(
            Offset(-radiusPx * 0.2, -radiusPx * 0.25), radiusPx * 0.3, _fill);
      case ObstacleKind.sombra:
        _fill.color = GameScene.shadow.withValues(alpha: 0.55);
        canvas.drawCircle(Offset.zero, radiusPx, _fill);
        _fill.color = GameScene.shadow.withValues(alpha: 0.25);
        canvas.drawCircle(Offset.zero, radiusPx * 1.35, _fill);
    }
  }
}

/// El camino de luz que dibuja el jugador. Decae con el tiempo (la estela
/// visual se apaga) y expone `pointAhead` para el seguimiento de las
/// luciérnagas.
class _TrailComponent extends Component {
  final List<_TrailPoint> _points = [];
  static const _minSegment = 8.0;
  static const _decayPerSecond = 0.5;

  bool get hasPoints => _points.isNotEmpty;

  /// Añade un punto si está lo bastante lejos del anterior. Devuelve la
  /// distancia añadida (para cobrar energía), o 0 si no se añadió nada.
  double addPoint(Vector2 p) {
    if (_points.isNotEmpty) {
      final last = _points.last.pos;
      final d = last.distanceTo(p);
      if (d < _minSegment) return 0;
      _points.add(_TrailPoint(p.clone()));
      return d;
    }
    _points.add(_TrailPoint(p.clone()));
    return 0;
  }

  /// Punto del camino más cercano a [from], avanzado `lookAhead` índices
  /// hacia el final de la lista (que es hacia donde se dibujó más
  /// recientemente / hacia el hogar).
  Vector2? pointAhead(Vector2 from, {int lookAhead = 4}) {
    if (_points.isEmpty) return null;
    var bestIndex = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < _points.length; i++) {
      final d = _points[i].pos.distanceToSquared(from);
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    final aheadIndex = math.min(_points.length - 1, bestIndex + lookAhead);
    return _points[aheadIndex].pos;
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final p in _points) {
      p.life -= _decayPerSecond * dt;
    }
    _points.removeWhere((p) => p.life <= 0);
  }

  static final Paint _glow = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final Paint _core = Paint()
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;
    for (var i = 0; i < _points.length - 1; i++) {
      final a = _points[i];
      final b = _points[i + 1];
      final alpha = a.life.clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;
      _glow
        ..color = GameScene.lightTrail.withValues(alpha: alpha * 0.45)
        ..strokeWidth = 14;
      canvas.drawLine(a.pos.toOffset(), b.pos.toOffset(), _glow);
      _core
        ..color = Colors.white.withValues(alpha: alpha * 0.9)
        ..strokeWidth = 4;
      canvas.drawLine(a.pos.toOffset(), b.pos.toOffset(), _core);
    }
  }
}

class _TrailPoint {
  _TrailPoint(this.pos) : life = 1.0;
  final Vector2 pos;
  double life;
}

/// Fondo del escenario: la imagen original, difuminada y oscurecida para que
/// las luciérnagas (que brillan por `BlendMode.screen`) resalten por encima.
class _BlurredBackground extends PositionComponent {
  _BlurredBackground({required this.image, required Vector2 screenSize})
      : super(size: screenSize);

  final Image image;

  @override
  void render(Canvas canvas) {
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    // `imageFilter` solo se aplica dentro de un saveLayer: dibuja la imagen
    // con el difuminado y luego un velo oscuro encima.
    canvas.saveLayer(
      bounds,
      Paint()..imageFilter = ImageFilter.blur(sigmaX: 7, sigmaY: 7),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      bounds,
      Paint(),
    );
    canvas.restore();
    canvas.drawRect(bounds, Paint()..color = const Color(0x40000000));
  }
}

/// Una luciérnaga guiada por el jugador. Boids simples (`seek`/`separate`)
/// más los estados temporales que le imponen los obstáculos. El sprite y la
/// luz de cola viven en `FireflySpriteComponent` (compartido con Proteger).
class FireflyGuideComponent extends FireflySpriteComponent {
  FireflyGuideComponent({
    required super.position,
    required this.home,
    required super.animation,
    super.size,
  }) : super(rotateWithVelocity: true);

  final HomeComponent home;
  static const maxSpeed = 130.0;
  static const maxForce = 6.0;

  bool arrived = false;

  double _dazedFor = 0;
  double _slowFor = 0;

  void daze(double seconds) => _dazedFor = math.max(_dazedFor, seconds);
  void slowFor(double seconds) => _slowFor = math.max(_slowFor, seconds * 1.1);

  void seek(Vector2 target) {
    if (arrived || _dazedFor > 0) return;
    final desired = (target - position);
    if (desired.length2 == 0) return;
    desired
      ..normalize()
      ..scale(maxSpeed);
    final steer = desired - velocity;
    if (steer.length > maxForce) {
      steer
        ..normalize()
        ..scale(maxForce);
    }
    velocity += steer;
  }

  void separate(List<FireflyGuideComponent> others) {
    if (arrived || _dazedFor > 0) return;
    final sum = Vector2.zero();
    var count = 0;
    for (final other in others) {
      if (identical(other, this) || other.arrived) continue;
      final d = position.distanceTo(other.position);
      if (d > 0 && d < 26) {
        final diff = (position - other.position)..scale(1 / d);
        sum.add(diff);
        count++;
      }
    }
    if (count == 0) return;
    sum
      ..scale(1 / count)
      ..normalize()
      ..scale(maxSpeed);
    final steer = sum - velocity;
    if (steer.length > maxForce * 1.5) {
      steer
        ..normalize()
        ..scale(maxForce * 1.5);
    }
    velocity += steer;
  }

  void stepPhysics(double dt) {
    if (arrived) return;
    if (_dazedFor > 0) {
      _dazedFor -= dt;
      velocity *= 0.9;
    }
    if (_slowFor > 0) _slowFor -= dt;

    final cap = _slowFor > 0 ? maxSpeed * 0.4 : maxSpeed;
    if (velocity.length > cap) {
      velocity
        ..normalize()
        ..scale(cap);
    }
    position += velocity * dt;
  }

  static final Paint _dazePaint = Paint()
    ..color = GameScene.onSceneMuted.withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  @override
  void render(Canvas canvas) {
    if (arrived) return;
    super.render(canvas);
    if (_dazedFor > 0) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x * 0.9,
        _dazePaint,
      );
    }
  }
}
