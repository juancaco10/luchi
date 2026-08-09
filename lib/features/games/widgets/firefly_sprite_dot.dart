import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../logic/firefly_sprite.dart';
import '../theme/game_palette.dart';
import 'firefly_art.dart';

/// Hoja de sprites compartida: se decodifica una sola vez para todos los
/// widgets de luciérnaga. Si falla la carga (o en tests sin asíncronía
/// real), el widget cae al arte vectorial de `FireflyArt` — la app nunca
/// se queda sin mascota por culpa de un asset.
final Future<ui.Image> _fireflySheetFuture = _loadSheet();

Future<ui.Image> _loadSheet() async {
  final data =
      await rootBundle.load('assets/images/games/firefly_spritesheet.jpg');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Una luciérnaga como widget, con el **mismo** sprite y la misma luz de
/// cola que los juegos Flame (Guiar, Proteger).
///
/// Reemplaza a `FireflyDot` (arte vectorial) en los juegos que no son Flame
/// (Sincronizar): la mascota se ve idéntica en toda la app. Hasta que la
/// hoja de sprites esté cargada se dibuja el vectorial, así nunca hay un
/// hueco ni un parpadeo al entrar.
///
/// [color] tiñe el sprite (los nodos de Sincronizar se distinguen por
/// color); [lit] enciende/apaga la luz de la cola; [animate] detiene el
/// aleteo y el parpadeo para listas e iconos estáticos.
class FireflySpriteDot extends StatefulWidget {
  const FireflySpriteDot({
    super.key,
    this.size = 48,
    this.color = GameScene.firefly,
    this.lit = true,
    this.animate = true,
  });

  final double size;
  final Color color;

  /// `false` la dibuja apagada (sprite oscurecido, sin luz de cola).
  final bool lit;

  /// `false` la deja quieta (listas largas, iconos estáticos).
  final bool animate;

  @override
  State<FireflySpriteDot> createState() => _FireflySpriteDotState();
}

class _FireflySpriteDotState extends State<FireflySpriteDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  ui.Image? _sheet;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
    _fireflySheetFuture.then((image) {
      if (mounted) setState(() => _sheet = image);
    });
  }

  @override
  void didUpdateWidget(FireflySpriteDot old) {
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
        builder: (_, __) {
          final seconds = _c.value * 1.8;
          final sheet = _sheet;
          if (sheet != null) {
            return CustomPaint(
              size: Size.square(widget.size),
              painter: _SpriteDotPainter(
                seconds: seconds,
                color: widget.color,
                lit: widget.lit,
                sheet: sheet,
              ),
            );
          }
          return CustomPaint(
            size: Size.square(widget.size),
            painter: _FallbackDotPainter(
              t: _c.value,
              color: widget.color,
              lit: widget.lit,
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja el sprite real: un frame de la hoja (el fondo negro desaparece
/// con `BlendMode.screen` sobre la escena nocturna), teñido con el color
/// del nodo, más la luz de la cola difuminada compartida con Flame.
class _SpriteDotPainter extends CustomPainter {
  const _SpriteDotPainter({
    required this.seconds,
    required this.color,
    required this.lit,
    required this.sheet,
  });

  final double seconds;
  final Color color;
  final bool lit;
  final ui.Image sheet;

  /// Color dominante del arte de la hoja; con él se calcula el tinte.
  static const _artColor = GameScene.firefly;

  @override
  void paint(Canvas canvas, Size size) {
    // Frame del aleteo: mismo ritmo que en Flame (0.09 s/frame).
    final frame = (seconds / FireflySprite.frameTime).floor() % 4;
    final col = frame % 2;
    final row = frame ~/ 2;
    final src = Rect.fromLTWH(
      col * FireflySprite.cellW,
      row * FireflySprite.cellH,
      FireflySprite.cellW,
      FireflySprite.cellH,
    );
    final dst = Offset.zero & size;

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..colorFilter = color == GameScene.firefly
          ? null
          : ColorFilter.matrix(_tintMatrix(color));
    canvas.drawImageRect(sheet, src, dst, paint);

    // Luz de la cola, idéntica a la de los juegos Flame.
    final tail = Offset(size.width / 2, size.height * 0.76);
    final pulse = 0.5 + 0.5 * math.sin(seconds * 4.5);
    FireflySprite.paintTail(
      canvas,
      tail,
      size.width * 0.11,
      pulse,
      intensity: lit ? 1.0 : 0.15,
    );

    if (!lit) {
      _dimBody.color = GameScene.fireflyDim.withValues(alpha: 0.55);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.28,
        _dimBody,
      );
    }
  }

  /// Tinte por escala de canales: el arte es amarillo de marca (#FFE87A);
  /// multiplicando cada canal por `target/art` el cuerpo casi blanco toma el
  /// color del nodo y el negro del fondo sigue siendo negro.
  static List<double> _tintMatrix(Color target) {
    const art = _artColor;
    double scale(double a, double b) => b == 0 ? 1.0 : a / b;
    return [
      scale(target.r, art.r), 0, 0, 0, 0,
      0, scale(target.g, art.g), 0, 0, 0,
      0, 0, scale(target.b, art.b), 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  static final Paint _dimBody = Paint()..style = PaintingStyle.fill;

  @override
  bool shouldRepaint(_SpriteDotPainter old) =>
      old.seconds != seconds ||
      old.color != color ||
      old.lit != lit ||
      old.sheet != sheet;
}

/// Respaldo vectorial (el aspecto de `FireflyDot`) mientras no llega la
/// hoja de sprites. Igual de nítido, solo sin la animación de frames.
class _FallbackDotPainter extends CustomPainter {
  const _FallbackDotPainter({
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
  bool shouldRepaint(_FallbackDotPainter old) =>
      old.t != t || old.color != color || old.lit != lit;
}
