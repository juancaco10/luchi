import 'package:flutter/material.dart';

import '../theme/game_palette.dart';

/// Las tres estrellas de un nivel. Un solo widget para el selector de
/// niveles, el hub y la pantalla de fin de nivel, así "2 de 3" se ve igual
/// en todas partes.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 18,
    this.animate = false,
    this.spacing = 2,
    this.outlineColor,
  });

  /// 0..3.
  final int stars;
  final double size;

  /// Aparecen una a una. Se usa solo al terminar un nivel — en una lista de
  /// diez niveles serían diez animaciones compitiendo por nada.
  final bool animate;

  final double spacing;

  /// Contorno oscuro opcional para que las estrellas resalten sobre fondos
  /// claros/dorados (p. ej. la tarjeta activa del selector de niveles).
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        final star = Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: earned
              ? GameScene.firefly
              : GameScene.onSceneMuted.withValues(alpha: 0.45),
          shadows: [
            if (outlineColor != null) ...[
              BoxShadow(color: outlineColor!, offset: const Offset(1, 1)),
              BoxShadow(color: outlineColor!, offset: const Offset(-1, 1)),
              BoxShadow(color: outlineColor!, offset: const Offset(1, -1)),
              BoxShadow(color: outlineColor!, offset: const Offset(-1, -1)),
            ],
            if (earned)
              const BoxShadow(
                color: GameScene.firefly,
                blurRadius: 12,
              ),
          ],
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: animate && earned
              ? _PoppingStar(delay: Duration(milliseconds: 220 * i), child: star)
              : star,
        );
      }),
    );
  }
}

class _PoppingStar extends StatefulWidget {
  const _PoppingStar({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  State<_PoppingStar> createState() => _PoppingStarState();
}

class _PoppingStarState extends State<_PoppingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
      child: widget.child,
    );
  }
}
