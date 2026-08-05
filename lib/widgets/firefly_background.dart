import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/firefly_colors.dart';

/// Animated floating firefly particle background.
/// Lightweight — uses a single CustomPainter + AnimationController.
class FireflyBackground extends StatefulWidget {
  final int count;
  final double intensity; // 0.0 – 1.0 opacity multiplier

  const FireflyBackground({
    super.key,
    this.count = 15,
    this.intensity = 0.5,
  });

  @override
  State<FireflyBackground> createState() => _FireflyBackgroundState();
}

class _FireflyBackgroundState extends State<FireflyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Firefly> _fireflies;
  final _rnd = Random();

  bool _generated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 365),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_generated) {
      _generated = true;
      _fireflies = List.generate(
        widget.count,
        (_) => _Firefly.random(_rnd, context.colors.secondary, context.colors.primary),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final elapsed = _controller.lastElapsedDuration?.inMicroseconds ?? 0;
          final t = elapsed / 1000000.0;
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _FireflyPainter(
              _fireflies,
              t,
              widget.intensity,
            ),
          );
        },
      ),
    );
  }
}

class _Firefly {
  // Ancla alejada de los bordes (15%-85% del lienzo): el recorrido amplio
  // se dibuja alrededor de este punto, así nunca queda una luciérnaga
  // "pegada" a un borde con su trayecto medio cortado por el límite de la
  // pantalla — el problema real del diseño anterior (órbita diminuta fija
  // alrededor de un punto que podía caer cerca del borde).
  final double anchorX;
  final double anchorY;

  // Amplitud del recorrido amplio, como fracción del ancho/alto — cada
  // luciérnaga cubre una porción real de la pantalla, no un punto fijo.
  final double ampX;
  final double ampY;

  // Periodo (segundos) del recorrido amplio: un poco más lento que antes
  // ("desacelera un poco"), y con dos periodos distintos por eje para que
  // el camino sea una curva orgánica, no una elipse perfecta y repetitiva.
  final double periodX;
  final double periodY;

  // Bamboleo rápido superpuesto, en píxeles — el aleteo fino de una
  // luciérnaga real dentro de su vuelo amplio.
  final double wobbleAmp;
  final double wobblePeriod;

  final double size;
  final double phase;
  final double flickerSpeed;
  final Color color;

  _Firefly({
    required this.anchorX,
    required this.anchorY,
    required this.ampX,
    required this.ampY,
    required this.periodX,
    required this.periodY,
    required this.wobbleAmp,
    required this.wobblePeriod,
    required this.size,
    required this.phase,
    required this.flickerSpeed,
    required this.color,
  });

  factory _Firefly.random(Random rnd, Color secondary, Color primary) {
    // Mix golden and green fireflies
    final isGreen = rnd.nextBool();
    return _Firefly(
      anchorX: 0.15 + rnd.nextDouble() * 0.7,
      anchorY: 0.15 + rnd.nextDouble() * 0.7,
      ampX: 0.22 + rnd.nextDouble() * 0.14,
      ampY: 0.16 + rnd.nextDouble() * 0.12,
      periodX: 34 + rnd.nextDouble() * 26,
      periodY: 28 + rnd.nextDouble() * 24,
      wobbleAmp: 10 + rnd.nextDouble() * 14,
      wobblePeriod: 4 + rnd.nextDouble() * 4,
      size: 1.5 + rnd.nextDouble() * 3.5,
      phase: rnd.nextDouble() * 2 * pi,
      flickerSpeed: 0.25 + rnd.nextDouble() * 0.65, // antes 0.3–0.8: un poco más lento
      color: isGreen ? secondary : primary,
    );
  }
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  final double t;
  final double intensity;

  _FireflyPainter(this.fireflies, this.t, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    for (final ff in fireflies) {
      // Recorrido amplio: dos armónicos por eje (periodo largo + un
      // bamboleo corto) alrededor del ancla. Es continuo para siempre —
      // sin salto ni reinicio — así que nunca se "corta" visualmente.
      final cx = ff.anchorX * size.width +
          sin(t / ff.periodX * 2 * pi + ff.phase) * ff.ampX * size.width +
          sin(t / ff.wobblePeriod * 2 * pi + ff.phase * 1.7) * ff.wobbleAmp;
      final cy = ff.anchorY * size.height +
          cos(t / ff.periodY * 2 * pi + ff.phase * 1.3) * ff.ampY * size.height +
          cos(t / (ff.wobblePeriod * 1.3) * 2 * pi + ff.phase * 0.6) *
              ff.wobbleAmp *
              0.6;

      // Flicker: blink with varying frequency per firefly (misma forma que
      // antes, solo con flickerSpeed ligeramente más bajo — "un poquito
      // nomás" más lento, no un cambio brusco de ritmo).
      final progress = t / 6.0 * ff.flickerSpeed + ff.phase;
      final flicker =
          (sin(progress * pi * 2 * (2 + ff.flickerSpeed * 3) + ff.phase) + 1) / 2;
      final alpha = (intensity * flicker * 200).toInt().clamp(0, 255);

      if (alpha < 5) continue;

      // Glow halo
      final haloPaint = Paint()
        ..color = ff.color.withAlpha((alpha * 0.3).toInt())
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ff.size * 3.5);
      canvas.drawCircle(Offset(cx, cy), ff.size * 2.5, haloPaint);

      // Core dot
      final corePaint = Paint()
        ..color = ff.color.withAlpha(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ff.size * 0.8);
      canvas.drawCircle(Offset(cx, cy), ff.size, corePaint);
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter old) => true;
}
