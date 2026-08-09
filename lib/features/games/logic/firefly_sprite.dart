import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../theme/game_palette.dart';

/// La luciérnaga de los juegos, en un solo sitio.
///
/// Antes cada juego dibujaba su propia versión vectorial (`FireflyArt`), y
/// "Guiar" usaba un sprite aparte. Desde aquí, **todos** los juegos (Flame y
/// widgets) comparten la misma hoja de sprites y la misma luz de cola
/// difuminada, para que la mascota se vea idéntica en pantalla.
///
/// **Rendimiento**: la luz de la cola se dibuja con un gradiente radial
/// (caída suave sin bordes duros, casi gratis) en vez de `MaskFilter.blur`,
/// que es un paso de GPU por llamada y hundiría el frame rate con muchas
/// luciérnagas. Los `Paint` son estáticos y se reconfiguran, nunca se crean
/// por frame.
abstract final class FireflySprite {
  /// La hoja es una cuadrícula 2×2 de sprites de 600×448. Cortar en 4
  /// columnas de 300 partía cada luciérnaga por la mitad.
  static const double cellW = 600.0;
  static const double cellH = 448.0;

  /// Segundos que dura cada frame; las alas baten suave.
  static const double frameTime = 0.09;

  /// Construye la animación de vuelo a partir de la hoja ya cargada.
  /// El orden de frames es fila a fila: (0,0), (0,1), (1,0), (1,1).
  static SpriteAnimation animation(Image sheet) {
    return SpriteAnimation([
      for (var row = 0; row < 2; row++)
        for (var col = 0; col < 2; col++)
          SpriteAnimationFrame(
            Sprite(
              sheet,
              srcPosition: Vector2(col * cellW, row * cellH),
              srcSize: Vector2(cellW, cellH),
            ),
            frameTime,
          ),
    ]);
  }

  /// Luz de la cola: destello bioluminiscente suave y difuminado. Gradiente
  /// radial (caída suave, sin bordes duros) con un núcleo brillante.
  /// [pulse] (0..1) es el parpadeo; [intensity] atenúa la luz entera
  /// (luciérnaga apagada, mojada...).
  static void paintTail(
    Canvas canvas,
    Offset tail,
    double tailR,
    double pulse, {
    double intensity = 1.0,
    Color color = GameScene.firefly,
  }) {
    if (intensity <= 0.02) return;
    _tailGlow.shader = Gradient.radial(
      tail,
      tailR * 2.6,
      [
        Color.lerp(color, Colors.white, 0.65)!
            .withValues(alpha: 0.9 * pulse * intensity),
        color.withValues(alpha: 0.22 * pulse * intensity),
        color.withValues(alpha: 0),
      ],
      const [0.0, 0.5, 1.0],
    );
    canvas.drawCircle(tail, tailR * 2.6, _tailGlow);
    _tailCore.color =
        Color.lerp(color, Colors.white, 0.8)!.withValues(alpha: 0.9 * pulse * intensity);
    canvas.drawCircle(tail, tailR * 0.5, _tailCore);
  }

  static final Paint _tailGlow = Paint()..style = PaintingStyle.fill;
  static final Paint _tailCore = Paint()..style = PaintingStyle.fill;
}

/// La luciérnaga como componente de Flame: sprite animado + luz de cola.
///
/// Usada por los juegos sobre Flame (Guiar, Proteger). El fondo negro de la
/// hoja se vuelve transparente con `BlendMode.screen` sobre la escena
/// nocturna. El estado "apagada" ([dimmed]) mantiene el sprite visible pero
/// sin luz y con un velo gris — que un niño vea que se apagó, y no que
/// "murió", es una decisión de diseño de "no violencia".
class FireflySpriteComponent extends SpriteAnimationComponent {
  FireflySpriteComponent({
    required super.animation,
    required super.position,
    super.size,
    double? radius,
    this.pulsePhase = 0,
    this.rotateWithVelocity = false,
  })  : _radius = radius,
        super(anchor: Anchor.center) {
    paint.blendMode = BlendMode.screen;
  }

  /// Radio de colisión en píxeles; por defecto la mitad del tamaño. Los
  /// juegos pueden usar un radio más pequeño que lo que se ve para ser
  /// más generosos con el jugador.
  final double? _radius;

  /// Desfase del parpadeo: si todas las luciérnagas comparten fase parecen
  /// clones; con fases distintas el enjambre vive.
  final double pulsePhase;

  /// Si `true`, el sprite rota según [velocity] (mirando hacia donde vuela).
  final bool rotateWithVelocity;

  /// Velocidad actual; la usa [rotateWithVelocity] y la física de cada juego.
  Vector2 velocity = Vector2.zero();

  /// Apagada: sprite oscurecido y sin luz de cola. Que un niño vea que la
  /// luciérnaga se apagó (y no que "murió") es decisión de diseño.
  bool dimmed = false;

  double _t = 0;

  /// Tiempo interno de animación (fase del parpadeo, vaivén). Público para
  /// que los juegos que no extienden esta clase (aunque sí lo hacen) puedan
  /// sincronizar su física con el sprite.
  double get animT => _t;

  /// Oculta la luciérnaga sin quitar la componente (perdida en Proteger,
  /// llegó a casa en Guiar...). Flame 1.38 no expone `isVisible` propio.
  bool visible = true;

  /// Radio de colisión efectivo (ver el parámetro `radius` del constructor).
  double get radius => _radius ?? size.x / 2;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  static final Paint _dimBody = Paint()..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final center = Offset(size.x / 2, size.y / 2);
    final angle = rotateWithVelocity && velocity.length2 > 1
        ? math.atan2(velocity.y, velocity.x) + math.pi / 2
        : 0.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.translate(-center.dx, -center.dy);

    super.render(canvas);

    final pulse = 0.5 + 0.5 * math.sin((_t + pulsePhase) * 4.5);
    FireflySprite.paintTail(
      canvas,
      Offset(size.x / 2, size.y * 0.76),
      size.x * 0.11,
      pulse,
      intensity: dimmed ? 0.12 : 1.0,
    );

    if (dimmed) {
      _dimBody.color = GameScene.fireflyDim.withValues(alpha: 0.55);
      canvas.drawCircle(center, size.x * 0.28, _dimBody);
    }

    canvas.restore();
  }
}
