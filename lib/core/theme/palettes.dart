import 'package:flutter/material.dart';

/// Private token source for [AppTheme] and [FireflyColors]. Split out of
/// the old single `AppColors` (which mixed both light and dark values in
/// one namespace, e.g. `cardSurface` vs `cardSurfaceLight`) so each theme
/// builds from one unambiguous set. Values are copied 1:1 from the old
/// `AppColors` — this file changes nothing visually, only where the
/// numbers live.
abstract class DarkPalette {
  static const Color background = Color(0xFF0B0F1A);
  static const Color surface = Color(0xFF131929);
  static const Color cardSurface = Color(0xFF1C2640);

  static const Color primary = Color(0xFFF5D020);
  static const Color primaryLight = Color(0xFFFFE87A);
  static const Color primaryDark = Color(0xFFD4A800);
  static const Color primaryGlow = Color(0x40F5D020);

  static const Color secondary = Color(0xFF72E26E);
  static const Color secondaryLight = Color(0xFFAEFF6E);
  static const Color secondaryGlow = Color(0x4072E26E);

  static const Color accent = Color(0xFF5B8BF5);
  static const Color accentGlow = Color(0x405B8BF5);

  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8A9BC4);
  static const Color textMuted = Color(0xFF4F6094);
  static const Color textOnPrimary = Color(0xFF0B0F1A);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);

  static const Color border = Color(0xFF2A3A60);
  static const Color divider = Color(0xFF1E2D4E);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1220), Color(0xFF0B0F1A), Color(0xFF0A0E18)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE87A), Color(0xFFF5D020)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFAEFF6E), Color(0xFF72E26E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2640), Color(0xFF151E35)],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlowShadow = [
    const BoxShadow(color: primaryGlow, blurRadius: 20, spreadRadius: 2),
  ];

  // Theme-invariant decorative tokens — no distinct light variant existed in
  // the old AppColors either, so both themes read these from DarkPalette
  // (same pattern as primaryGradient/greenGradient below).
  static List<BoxShadow> greenGlowShadow = [
    const BoxShadow(color: secondaryGlow, blurRadius: 16, spreadRadius: 1),
  ];
}

abstract class LightPalette {
  static const Color background = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFE8EEF5);

  // Antes amarillo (D4A800), heredado sin adaptar del tema oscuro: sobre el
  // fondo casi blanco de este tema, cualquier ícono/acento en amarillo queda
  // lavado. El verde es el acento real del modo claro desde aquí.
  static const Color primary = Color(0xFF2E9E3A);
  static const Color primaryLight = Color(0xFF72E26E); // solo rellenos/glows, nunca texto suelto
  static const Color primaryGlow = Color(0x402E9E3A);

  static const Color secondary = Color(0xFF2E9E3A);
  static const Color secondaryGlow = Color(0x402E9E3A);

  static const Color accent = Color(0xFF5B8BF5);
  static const Color accentGlow = Color(0x405B8BF5);

  // Antes los tres en negro puro (#000000): sin jerarquía entre texto
  // principal/secundario/atenuado, un mismo negro para todo.
  static const Color textPrimary = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF7A8699);
  // Blanco sobre el verde de arriba da 3.46:1 (insuficiente para texto de
  // botón); oscuro da 6.1:1. Mismo patrón que ya usa el tema oscuro (amarillo
  // brillante + texto casi negro encima).
  static const Color textOnPrimary = Color(0xFF0A2A10);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);

  static const Color border = Color(0xFFD6DEE9);
  static const Color divider = Color(0xFFE3E9F2);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF72E26E), Color(0xFF2E9E3A)],
  );

  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF72E26E), Color(0xFF2E9E3A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFE8EEF5)],
  );

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> primaryGlowShadow = [
    const BoxShadow(color: primaryGlow, blurRadius: 20, spreadRadius: 2),
  ];

  static List<BoxShadow> greenGlowShadow = [
    const BoxShadow(color: secondaryGlow, blurRadius: 16, spreadRadius: 1),
  ];
}
