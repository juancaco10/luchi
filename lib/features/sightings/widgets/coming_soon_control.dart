import 'package:flutter/material.dart';
import '../../../core/theme/firefly_colors.dart';
import '../../../core/utils/constants.dart';

/// Control que se dibuja como el diseño final (campana, lupa, filtros,
/// selector de país...) pero cuya función todavía no existe.
///
/// Un botón mudo se lee, para un niño de 6-12 años, como "la app está
/// rota", y lo empuja a tocarlo varias veces seguidas. Este widget, en vez
/// de eso, se atenúa y — al tocarlo — responde con un aviso honesto de
/// "muy pronto". Cuando la función exista de verdad, activarla es tan
/// simple como pasar un [onPressed] no nulo: deja de atenuarse y de
/// mostrar el aviso, e invoca el callback real.
class ComingSoonControl extends StatelessWidget {
  const ComingSoonControl({
    super.key,
    required this.child,
    required this.message,
    this.onPressed,
    this.semanticsLabel,
  });

  final Widget child;
  final String message;
  final VoidCallback? onPressed;
  final String? semanticsLabel;

  bool get _enabled => onPressed != null;

  void _handleTap(BuildContext context) {
    if (_enabled) {
      onPressed!();
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Nunito', color: context.colors.onSurface),
        ),
        backgroundColor: context.firefly.cardSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel == null ? null : '$semanticsLabel, próximamente',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppConstants.minTouchTarget,
              minHeight: AppConstants.minTouchTarget,
            ),
            child: Center(
              child: Opacity(
                opacity: _enabled ? 1.0 : AppConstants.disabledOpacity,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
