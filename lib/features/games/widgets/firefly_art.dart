import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/game_palette.dart';

/// El dibujo de una luciérnaga, en un solo sitio.
///
/// Lo comparten los cinco juegos (dos de ellos sobre Flame, tres sobre
/// widgets Flutter), así el bicho se ve exactamente igual en todos: es la
/// mascota del producto, no un adorno por pantalla. Al ser vectorial es
/// nítido en cualquier densidad y no pesa nada en el APK.
///
/// **Rendimiento**: el halo se dibuja con tres círculos concéntricos de alfa
/// decreciente, no con `MaskFilter.blur`. El blur es un paso de GPU por
/// llamada y con 30 luciérnagas en pantalla hunde el frame rate en gama
/// media; los círculos son prácticamente gratis y a este tamaño se ven igual.
/// Los `Paint` son estáticos y se reconfiguran, nunca se crean por frame.
abstract final class FireflyArt {
  static final Paint _fill = Paint()..style = PaintingStyle.fill;
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  /// Dibuja una luciérnaga centrada en [center].
  ///
  /// [radius] es el radio del cuerpo luminoso; el halo ocupa unas 3 veces
  /// más. [glow] (0..1) es la intensidad del destello — animarlo con un seno
  /// da el parpadeo bioluminiscente. [angle] orienta las alas hacia donde
  /// vuela (0 = hacia arriba).
  static void draw(
    Canvas canvas,
    Offset center,
    double radius, {
    Color color = GameScene.firefly,
    double glow = 1.0,
    double angle = 0,
    double wingPhase = 0,
    double opacity = 1.0,
  }) {
    if (opacity <= 0.01) return;
    final g = glow.clamp(0.0, 1.0);

    // Halo: tres capas, de fuera a dentro.
    _fill.color = color.withValues(alpha: 0.10 * g * opacity);
    canvas.drawCircle(center, radius * 3.4, _fill);
    _fill.color = color.withValues(alpha: 0.18 * g * opacity);
    canvas.drawCircle(center, radius * 2.2, _fill);
    _fill.color = color.withValues(alpha: 0.34 * g * opacity);
    canvas.drawCircle(center, radius * 1.5, _fill);

    // Alas: dos arcos que baten. Se dibujan por debajo del cuerpo.
    final flap = 0.55 + 0.35 * math.sin(wingPhase);
    _stroke
      ..color = Colors.white.withValues(alpha: 0.30 * opacity)
      ..strokeWidth = radius * 0.28;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    for (final side in const [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(0, radius * 0.1)
        ..quadraticBezierTo(
          side * radius * 2.0 * flap,
          -radius * 1.1,
          side * radius * 0.35,
          -radius * 1.5,
        );
      canvas.drawPath(path, _stroke);
    }
    canvas.restore();

    // Cuerpo: núcleo casi blanco sobre el color de la luciérnaga.
    _fill.color = color.withValues(alpha: opacity);
    canvas.drawCircle(center, radius, _fill);
    _fill.color = Color.lerp(color, Colors.white, 0.75)!
        .withValues(alpha: (0.55 + 0.45 * g) * opacity);
    canvas.drawCircle(center.translate(0, -radius * 0.12), radius * 0.5, _fill);
  }

  /// Versión apagada: la luciérnaga sigue ahí pero sin luz (mojada, en la
  /// sombra o sin energía). Nunca desaparece de golpe — que un niño vea que
  /// se apagó, y no que "murió", es una decisión de diseño.
  static void drawDim(
    Canvas canvas,
    Offset center,
    double radius, {
    double opacity = 1.0,
  }) {
    _fill.color = GameScene.fireflyDim.withValues(alpha: 0.9 * opacity);
    canvas.drawCircle(center, radius, _fill);
    _fill.color = GameScene.fireflyDim.withValues(alpha: 0.25 * opacity);
    canvas.drawCircle(center, radius * 1.6, _fill);
  }

  /// Genera una imagen de la luciérnaga para usarla como sprite cacheado.
  /// Útil si algún día hace falta dibujar cientos a la vez: se pinta una sola
  /// vez a textura y luego se `drawImage`. Hoy no lo necesita ningún juego.
  static Future<ui.Image> rasterize(double size, {Color color = GameScene.firefly}) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    draw(canvas, Offset(size / 2, size / 2), size / 7, color: color);
    return recorder.endRecording().toImage(size.toInt(), size.toInt());
  }
}

/// Una luciérnaga como widget, con su parpadeo propio. La usan los juegos
/// que no son Flame (Sincronizar, Restaurar) y las pantallas de resumen.
class FireflyDot extends StatefulWidget {
  const FireflyDot({
    super.key,
    this.size = 48,
    this.color = GameScene.firefly,
    this.lit = true,
    this.animate = true,
  });

  final double size;
  final Color color;

  /// `false` la dibuja apagada.
  final bool lit;

  /// `false` la deja quieta (listas largas, iconos estáticos).
  final bool animate;

  @override
  State<FireflyDot> createState() => _FireflyDotState();
}

class _FireflyDotState extends State<FireflyDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(FireflyDot old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.animate && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: _FireflyDotPainter(
            t: _c.value,
            color: widget.color,
            lit: widget.lit,
          ),
        ),
      ),
    );
  }
}

class _FireflyDotPainter extends CustomPainter {
  const _FireflyDotPainter({
    required this.t,
    required this.color,
    required this.lit,
  });

  final double t;
  final Color color;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 7;
    if (!lit) {
      FireflyArt.drawDim(canvas, center, radius);
      return;
    }
    final glow = 0.55 + 0.45 * math.sin(t * 2 * math.pi);
    FireflyArt.draw(
      canvas,
      center,
      radius,
      color: color,
      glow: glow,
      wingPhase: t * 2 * math.pi * 6,
    );
  }

  @override
  bool shouldRepaint(_FireflyDotPainter old) =>
      old.t != t || old.color != color || old.lit != lit;
}
