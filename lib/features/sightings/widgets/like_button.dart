import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sighting_model.dart';
import '../providers/sightings_provider.dart';

/// Corazón + contador, clicable. `GestureDetector` propio para que tocarlo
/// no dispare el gesto del contenedor padre (abrir el modal de detalle) —
/// solo da o quita el corazón, con animación de "pop" al dar.
///
/// Estilos por contexto: sobre una foto (`overlay: true`, por defecto) se
/// pinta en blanco con sombra; dentro de una tarjeta de superficie clara
/// (`overlay: false`) usa `unlikedColor` y sin sombras.
class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({
    super.key,
    required this.sighting,
    this.overlay = true,
    this.unlikedColor,
  });

  final SightingModel sighting;

  /// `true` cuando el botón va encima de una foto (blanco + sombra);
  /// `false` cuando va sobre la superficie de la tarjeta.
  final bool overlay;
  final Color? unlikedColor;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0,
    upperBound: 0.35,
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (widget.sighting.id == null) return;
    final wasLiked = widget.sighting.likedByMe;
    if (!wasLiked) {
      // Solo hace el pop al dar corazón, no al quitarlo — el gesto
      // afirmativo se celebra, el negativo no necesita ceremonia.
      _pop.forward(from: 0).then((_) => _pop.reverse());
    }
    await ref.read(sightingsProvider.notifier).toggleLike(widget.sighting.id!);
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.sighting.likedByMe;
    final count = widget.sighting.likesCount;
    final unlikedColor = widget.unlikedColor ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.grey;
    final shadows = widget.overlay
        ? const [Shadow(color: Colors.black54, blurRadius: 4)]
        : null;
    final color = liked
        ? const Color(0xFFFF5C7A)
        : (widget.overlay ? Colors.white : unlikedColor);

    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Área táctil un poco mayor que el icono visible, sin desplazar el
        // layout — el icono real ya ronda los 14px.
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) => Transform.scale(
            scale: 1 + _pop.value,
            child: child,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: color,
                shadows: shadows,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  shadows: shadows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
