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
      duration: const Duration(seconds: 6),
    )..repeat();
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
        builder: (_, __) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _FireflyPainter(
            _fireflies,
            _controller.value,
            widget.intensity,
          ),
        ),
      ),
    );
  }
}

class _Firefly {
  final double startX;
  final double startY;
  final double size;
  final double speed;
  final double phase;
  final double driftRadius;
  final Color color;

  _Firefly({
    required this.startX,
    required this.startY,
    required this.size,
    required this.speed,
    required this.phase,
    required this.driftRadius,
    required this.color,
  });

  factory _Firefly.random(Random rnd, Color secondary, Color primary) {
    // Mix golden and green fireflies
    final isGreen = rnd.nextBool();
    return _Firefly(
      startX: rnd.nextDouble(),
      startY: rnd.nextDouble(),
      size: 1.5 + rnd.nextDouble() * 3.5,
      speed: 0.3 + rnd.nextDouble() * 0.8,
      phase: rnd.nextDouble() * 2 * pi,
      driftRadius: 15 + rnd.nextDouble() * 30,
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
      final progress = (t * ff.speed + ff.phase) % 1.0;
      final angle = progress * 2 * pi;

      // Drift in a small circle + upward float
      final cx = ff.startX * size.width +
          sin(angle * 2.3) * ff.driftRadius;
      final cy = ff.startY * size.height +
          cos(angle * 1.7) * ff.driftRadius * 0.6;

      // Flicker: blink with varying frequency per firefly
      final flicker =
          (sin(progress * pi * 2 * (2 + ff.speed * 3) + ff.phase) + 1) /
              2;
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
