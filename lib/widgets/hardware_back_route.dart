import 'package:flutter/material.dart';

/// Ata el botón de retroceder del sistema (físico o gesto) al mismo
/// destino que la flecha propia de la pantalla.
///
/// Rutas fuera del `StatefulShellRoute` (perfil, ajustes, mis
/// avistamientos, formulario de avistamiento...) se alcanzan con
/// `context.go()`, que sustituye toda la pila de navegación en vez de
/// apilar — así, sin esto, el retroceso del sistema no tiene a dónde
/// volver y cierra la app en vez de llevar a la pantalla anterior. Mismo
/// patrón que ya usa `GameScaffold` para las pantallas de minijuegos.
class HardwareBackRoute extends StatelessWidget {
  const HardwareBackRoute({super.key, required this.onBack, required this.child});

  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: child,
    );
  }
}
