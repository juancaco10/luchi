import 'package:flutter/material.dart';

import '../../../core/theme/palettes.dart';

/// Colores de la **escena** de los minijuegos.
///
/// Excepción documentada a la regla de `CLAUDE.md` ("todo por `context.colors`
/// / `context.firefly`"): un bosque de noche es de noche en los dos temas de
/// la app. Poner la escena en modo claro no la haría más accesible, la haría
/// ilegible — el gameplay entero se basa en luces sobre un fondo oscuro.
///
/// La regla se respeta donde importa: aquí hay **un solo sitio** con hex, en
/// vez de treinta repartidos por las pantallas, y todo se deriva de
/// `DarkPalette` para que la marca siga siendo la misma. El *chrome* de los
/// juegos (hub, selector de niveles, diálogos, resúmenes) sí usa el tema
/// normal y respeta el modo claro.
abstract final class GameScene {
  /// Fondo del cielo nocturno, de arriba (más oscuro) a abajo.
  static const skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF050912), Color(0xFF0B1225), Color(0xFF122038)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Color de una luciérnaga viva. Es el amarillo de marca.
  static const firefly = DarkPalette.primaryLight;

  /// Variante verde, para mezclar en enjambres y que no parezcan clones.
  static const fireflyGreen = DarkPalette.secondaryLight;

  /// Luciérnaga apagada (mojada, en sombra o sin energía).
  static const fireflyDim = Color(0xFF5A6A85);

  /// La luz que dibuja el jugador.
  static const lightTrail = Color(0xFFAEF7C8);

  /// El hogar: el árbol al que hay que llegar.
  static const home = DarkPalette.secondary;

  static const rock = Color(0xFF3A4358);
  static const rockEdge = Color(0xFF566179);
  static const water = Color(0xFF2E5C8A);
  static const shadow = Color(0xFF120A22);

  /// Amenazas de "Proteger la Luz".
  static const rain = Color(0xFF7FB4E8);
  static const cloud = Color(0xFF4A5570);

  /// Escudo del guardián.
  static const shield = Color(0xFF63F1E2);

  /// Texto sobre la escena. Siempre claro, siempre sobre fondo oscuro.
  static const onScene = Color(0xFFF2F6FF);
  static const onSceneMuted = Color(0xFFA8B6D0);

  /// Refuerzo positivo / error suave. El error nunca es rojo agresivo:
  /// el público son niños de 6–12 y fallar tiene que invitar a reintentar.
  static const good = DarkPalette.secondary;
  static const soft = Color(0xFFE8A0A0);

  /// Superficie de tarjetas y HUD dentro de la escena.
  static const panel = Color(0xCC101A2E);
  static const panelBorder = Color(0x33FFFFFF);
}
