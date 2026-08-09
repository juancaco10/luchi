import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/game_palette.dart';

/// Cuenta atrás 3-2-1 antes de que empiece la partida.
///
/// Bloquea el toque mientras dura (para que nadie gaste energía antes de
/// tiempo) y desaparece sola al llegar a cero.
class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({super.key, required this.onFinished});

  /// Se llama cuando la cuenta llega a cero.
  final VoidCallback onFinished;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  static const _tick = Duration(milliseconds: 700);

  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) {
      if (_count <= 1) {
        _timer?.cancel();
        widget.onFinished();
        setState(() => _count = 0);
      } else {
        setState(() => _count--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    // `AbsorbPointer`, no `IgnorePointer`: la cuenta tiene que bloquear el
    // toque de verdad — con IgnorePointer los eventos pasaban de largo y
    // llegaban al juego de debajo (gastar energía en Guiar, mover el
    // escudo en Proteger) durante el 3-2-1.
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: child,
          ),
          child: Text(
            '$_count',
            key: ValueKey(_count),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: GameScene.firefly,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
