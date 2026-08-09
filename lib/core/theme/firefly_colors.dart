import 'package:flutter/material.dart';
import 'palettes.dart';

/// Tokens de marca que no encajan en el [ColorScheme] de Material (halo de
/// luciérnaga, gradientes, sombra de tarjeta). Se registra en ambos temas
/// (`AppTheme.darkTheme`/`lightTheme`) y se lee vía `context.firefly`, nunca
/// directamente por `Color(0x...)` sueltos en una pantalla.
@immutable
class FireflyColors extends ThemeExtension<FireflyColors> {
  const FireflyColors({
    required this.glow,
    required this.greenGlow,
    required this.cardSurface,
    required this.cardBorder,
    required this.accent,
    required this.accentGlow,
    required this.success,
    required this.warning,
    required this.backgroundGradient,
    required this.primaryGradient,
    required this.greenGradient,
    required this.cardGradient,
    required this.cardShadow,
    required this.glowShadow,
    required this.greenGlowShadow,
  });

  final Color glow;
  final Color greenGlow;
  final Color cardSurface;
  final Color cardBorder;
  final Color accent;
  final Color accentGlow;
  final Color success;
  final Color warning;
  final Gradient? backgroundGradient;
  final Gradient primaryGradient;
  final Gradient greenGradient;
  final Gradient cardGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> glowShadow;
  final List<BoxShadow> greenGlowShadow;

  static final dark = FireflyColors(
    glow: DarkPalette.primaryGlow,
    greenGlow: DarkPalette.secondaryGlow,
    cardSurface: DarkPalette.cardSurface,
    cardBorder: DarkPalette.border,
    accent: DarkPalette.accent,
    accentGlow: DarkPalette.accentGlow,
    success: DarkPalette.success,
    warning: DarkPalette.warning,
    backgroundGradient: DarkPalette.backgroundGradient,
    primaryGradient: DarkPalette.primaryGradient,
    greenGradient: DarkPalette.greenGradient,
    cardGradient: DarkPalette.cardGradient,
    cardShadow: DarkPalette.cardShadow,
    glowShadow: DarkPalette.primaryGlowShadow,
    greenGlowShadow: DarkPalette.greenGlowShadow,
  );

  static final light = FireflyColors(
    glow: LightPalette.primaryGlow,
    greenGlow: DarkPalette.secondaryGlow,
    cardSurface: LightPalette.cardSurface,
    cardBorder: LightPalette.border,
    accent: LightPalette.accent,
    accentGlow: DarkPalette.accentGlow,
    success: LightPalette.success,
    warning: LightPalette.warning,
    backgroundGradient: null,
    primaryGradient: DarkPalette.primaryGradient,
    greenGradient: DarkPalette.greenGradient,
    cardGradient: LightPalette.cardGradient,
    cardShadow: LightPalette.cardShadow,
    glowShadow: LightPalette.primaryGlowShadow,
    greenGlowShadow: DarkPalette.greenGlowShadow,
  );

  @override
  FireflyColors copyWith({
    Color? glow,
    Color? greenGlow,
    Color? cardSurface,
    Color? cardBorder,
    Color? accent,
    Color? accentGlow,
    Color? success,
    Color? warning,
    Gradient? backgroundGradient,
    Gradient? primaryGradient,
    Gradient? greenGradient,
    Gradient? cardGradient,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? glowShadow,
    List<BoxShadow>? greenGlowShadow,
  }) {
    return FireflyColors(
      glow: glow ?? this.glow,
      greenGlow: greenGlow ?? this.greenGlow,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      accent: accent ?? this.accent,
      accentGlow: accentGlow ?? this.accentGlow,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      greenGradient: greenGradient ?? this.greenGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      cardShadow: cardShadow ?? this.cardShadow,
      glowShadow: glowShadow ?? this.glowShadow,
      greenGlowShadow: greenGlowShadow ?? this.greenGlowShadow,
    );
  }

  @override
  FireflyColors lerp(ThemeExtension<FireflyColors>? other, double t) {
    if (other is! FireflyColors) return this;
    return FireflyColors(
      glow: Color.lerp(glow, other.glow, t)!,
      greenGlow: Color.lerp(greenGlow, other.greenGlow, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      backgroundGradient:
          Gradient.lerp(backgroundGradient, other.backgroundGradient, t),
      primaryGradient:
          Gradient.lerp(primaryGradient, other.primaryGradient, t)!,
      greenGradient: Gradient.lerp(greenGradient, other.greenGradient, t)!,
      cardGradient: Gradient.lerp(cardGradient, other.cardGradient, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      glowShadow: t < 0.5 ? glowShadow : other.glowShadow,
      greenGlowShadow: t < 0.5 ? greenGlowShadow : other.greenGlowShadow,
    );
  }
}

extension FireflyTheme on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  FireflyColors get firefly => Theme.of(this).extension<FireflyColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
