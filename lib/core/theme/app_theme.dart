import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firefly_colors.dart';
import 'palettes.dart';
import '../utils/constants.dart';

/// Realce de foco para navegación con D-pad/teclado/mando (Android TV,
/// pantallas interactivas): un borde grueso del color de marca, visible
/// desde el sofá — el tinte translúcido por defecto de Material sobre un
/// botón ya coloreado es prácticamente invisible. Se aplica sobre el
/// `ButtonStyle` que ya arma `styleFrom`, así que el resto de estados
/// (hover, pressed, disabled) quedan intactos.
ButtonStyle _withFocusRing(ButtonStyle base, Color ring) {
  return base.copyWith(
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: ring, width: 3);
      }
      return base.side?.resolve(states);
    }),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return ring.withValues(alpha: 0.18);
      }
      return base.overlayColor?.resolve(states);
    }),
  );
}

abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DarkPalette.background,
      // Realce por defecto para InkWell/InkResponse (menú inferior,
      // tarjetas, filas de ajustes...) al recibir foco de D-pad/teclado —
      // sin esto, Material usa un tinte casi imperceptible sobre fondos
      // oscuros. Los botones Material tienen además su propio borde de
      // foco explícito (ver `_withFocusRing`).
      focusColor: DarkPalette.accent.withValues(alpha: 0.24),
      colorScheme: const ColorScheme.dark(
        primary: DarkPalette.primary,
        secondary: DarkPalette.secondary,
        surface: DarkPalette.surface,
        error: DarkPalette.error,
        onPrimary: DarkPalette.textOnPrimary,
        onSecondary: DarkPalette.textOnPrimary,
        onSurface: DarkPalette.textPrimary,
        onError: DarkPalette.textPrimary,
      ),
      extensions: [FireflyColors.dark],

      // ── Typography ──────────────────────────────────────────
      // Base +2pt sobre el diseño original: público de 6-12 años, y una
      // fuente algo mayor reduce cuánto se rompe el layout al activar
      // fuentes grandes del sistema (ver T0 del plan de accesibilidad).
      textTheme: GoogleFonts.nunitoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: DarkPalette.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: DarkPalette.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: DarkPalette.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: DarkPalette.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DarkPalette.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DarkPalette.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: DarkPalette.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: DarkPalette.textSecondary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DarkPalette.textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DarkPalette.textOnPrimary,
            letterSpacing: 0.5,
          ),
          labelMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DarkPalette.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DarkPalette.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: DarkPalette.textPrimary,
        ),
        iconTheme: IconThemeData(color: DarkPalette.textPrimary),
      ),

      // ── Cards ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: DarkPalette.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: DarkPalette.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Buttons ──────────────────────────────────────────────
      // minimumSize 48dp: objetivo táctil mínimo recomendado, más aún con
      // público infantil (ver hallazgo de accesibilidad en el plan).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _withFocusRing(
          ElevatedButton.styleFrom(
            backgroundColor: DarkPalette.primary,
            foregroundColor: DarkPalette.textOnPrimary,
            elevation: 0,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          DarkPalette.accent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _withFocusRing(
          OutlinedButton.styleFrom(
            foregroundColor: DarkPalette.primary,
            side: const BorderSide(color: DarkPalette.primary, width: 1.5),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          DarkPalette.accent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _withFocusRing(
          TextButton.styleFrom(
            foregroundColor: DarkPalette.primary,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          DarkPalette.accent,
        ),
      ),

      // ── Input Fields ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DarkPalette.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: DarkPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: DarkPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: DarkPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: DarkPalette.error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: DarkPalette.textMuted,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: DarkPalette.textSecondary,
          fontSize: 16,
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DarkPalette.surface,
        selectedItemColor: Color(0xFFB2FF59), // yellowish green
        unselectedItemColor: DarkPalette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: DarkPalette.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Progress ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DarkPalette.primary,
        linearTrackColor: DarkPalette.border,
      ),

      // ── Chip ─────────────────────────────────────────────────
      // `selectedColor` en relleno sólido, no el tinte de `primaryGlow`
      // (25% alpha): un chip seleccionado necesita contraste de verdad con
      // su etiqueta, no una insinuación de color.
      chipTheme: ChipThemeData(
        backgroundColor: DarkPalette.cardSurface,
        selectedColor: DarkPalette.primary,
        disabledColor: DarkPalette.surface,
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: DarkPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: DarkPalette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: LightPalette.background,
      focusColor: LightPalette.accent.withValues(alpha: 0.20),
      colorScheme: const ColorScheme.light(
        primary: LightPalette.primary,
        secondary: LightPalette.secondary,
        surface: LightPalette.surface,
        error: LightPalette.error,
        onPrimary: LightPalette.textOnPrimary,
        onSecondary: LightPalette.textOnPrimary,
        onSurface: LightPalette.textPrimary,
        onError: LightPalette.textOnPrimary,
      ),
      extensions: [FireflyColors.light],

      // ── Typography ──────────────────────────────────────────
      textTheme: GoogleFonts.nunitoTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: LightPalette.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: LightPalette.textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: LightPalette.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: LightPalette.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LightPalette.textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: LightPalette.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: LightPalette.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: LightPalette.textSecondary,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: LightPalette.textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: LightPalette.textOnPrimary,
            letterSpacing: 0.5,
          ),
          labelMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LightPalette.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: LightPalette.textMuted,
            letterSpacing: 0.8,
          ),
        ),
      ),

      // ── AppBar ───────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: LightPalette.textPrimary,
        ),
        iconTheme: IconThemeData(color: LightPalette.textPrimary),
      ),

      // ── Cards ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: LightPalette.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: const BorderSide(color: LightPalette.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Buttons ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _withFocusRing(
          ElevatedButton.styleFrom(
            backgroundColor: LightPalette.primary,
            foregroundColor: LightPalette.textOnPrimary,
            elevation: 0,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          LightPalette.accent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _withFocusRing(
          OutlinedButton.styleFrom(
            foregroundColor: LightPalette.primary,
            side: const BorderSide(color: LightPalette.primary, width: 1.5),
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          LightPalette.accent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _withFocusRing(
          TextButton.styleFrom(
            foregroundColor: LightPalette.primary,
            minimumSize: const Size(48, 48),
            textStyle: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          LightPalette.accent,
        ),
      ),

      // ── Input Fields ─────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LightPalette.cardSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: LightPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: LightPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: LightPalette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: LightPalette.error),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: LightPalette.textMuted,
          fontSize: 16,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: LightPalette.textSecondary,
          fontSize: 16,
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LightPalette.surface,
        selectedItemColor: LightPalette.secondary, // verde amarillento
        unselectedItemColor: LightPalette.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Divider ───────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: LightPalette.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Progress ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: LightPalette.primary,
        linearTrackColor: LightPalette.border,
      ),

      // ── Chip ─────────────────────────────────────────────────
      // Mismo criterio que el tema oscuro: relleno sólido, no tinte. Antes
      // era `primaryGlow` (amarillo al 25%), casi indistinguible del fondo
      // blanco — la etiqueta seleccionada (texto blanco fijo en
      // sighting_date_filter.dart) quedaba prácticamente ilegible encima.
      chipTheme: ChipThemeData(
        backgroundColor: LightPalette.cardSurface,
        selectedColor: LightPalette.primary,
        disabledColor: LightPalette.surface,
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          color: LightPalette.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: LightPalette.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
