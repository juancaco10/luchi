import 'package:flutter/material.dart';

/// Calcula un factor de escala para que una pantalla quepa sin scroll.
///
/// [naturalHeight] es la altura que el contenido necesita a tamaño normal
/// (medida en un teléfono de referencia). Si la altura disponible es
/// menor, [builder] recibe un `scale` entre [minScale] y 1.0 para reducir
/// separaciones y elementos decorativos — nunca crece por encima de 1.0
/// en pantallas grandes.
///
/// Solo se usa para espaciados (SizedBox) y tamaños decorativos (logo,
/// tarjetas). Los textos y los objetivos táctiles (botones, campos) no se
/// escalan aquí: los primeros por legibilidad, los segundos porque no
/// deben bajar del mínimo táctil de 48dp — ver AppTheme.
class ScreenFitter extends StatelessWidget {
  const ScreenFitter({
    super.key,
    required this.naturalHeight,
    required this.builder,
    this.minScale = 0.6,
  });

  final double naturalHeight;
  final double minScale;
  final Widget Function(BuildContext context, double scale) builder;

  @override
  Widget build(BuildContext context) {
    // Usamos el tamaño real de la pantalla en lugar de constraints.maxHeight
    // para que la escala no se reduzca drásticamente cuando se abre el teclado
    // y el Scaffold reduce su tamaño.
    final available = MediaQuery.sizeOf(context).height;
    final scale = (available > 0)
        ? (available / naturalHeight).clamp(minScale, 1.0)
        : 1.0;
    return builder(context, scale);
  }
}
