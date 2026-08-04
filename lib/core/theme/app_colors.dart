import 'package:flutter/material.dart';

/// Guardianes de las Luciérnagas — Color System
/// Theme: Night-sky magic with warm firefly glow
abstract class AppColors {
  // ── Backgrounds ─────────────────────────────────────────────
  static const Color background = Color(0xFF0B0F1A);
  static const Color backgroundLight = Color(0xFFF4F7FB);
  static const Color surface = Color(0xFF131929);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFF1C2640);
  static const Color cardSurfaceLight = Color(0xFFE8EEF5);

  // ── Primary — Firefly Golden Glow ────────────────────────────
  static const Color primary = Color(0xFFF5D020);
  static const Color primaryLight = Color(0xFFFFE87A);
  static const Color primaryDark = Color(0xFFD4A800);
  static const Color primaryGlow = Color(0x40F5D020); // 25% opacity glow

  // ── Secondary — Nature Green Glow ───────────────────────────
  static const Color secondary = Color(0xFF72E26E);
  static const Color secondaryLight = Color(0xFFAEFF6E);
  static const Color secondaryDark = Color(0xFF4CAF50);
  static const Color secondaryGlow = Color(0x4072E26E);

  // ── Accent — Soft Blue/Teal ──────────────────────────────────
  static const Color accent = Color(0xFF5B8BF5);
  static const Color accentLight = Color(0xFF8AAAFF);
  static const Color accentGlow = Color(0x405B8BF5);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textPrimaryLight = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF8A9BC4);
  static const Color textSecondaryLight = Color(0xFF5A6B8A);
  static const Color textMuted = Color(0xFF4F6094);
  static const Color textMutedLight = Color(0xFF8F9FB9);
  static const Color textOnPrimary = Color(0xFF0B0F1A);
  static const Color textOnPrimaryLight = Color(0xFFFFFFFF);

  // ── Status ───────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFE57373);

  // ── Borders & Dividers ───────────────────────────────────────
  static const Color border = Color(0xFF2A3A60);
  static const Color borderLight = Color(0xFF3A4E7A);
  static const Color divider = Color(0xFF1E2D4E);

  // ── Gradients ────────────────────────────────────────────────
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

  static const LinearGradient missionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF243050), Color(0xFF1A2340)],
  );

  // ── Shadows ──────────────────────────────────────────────────
  static List<BoxShadow> primaryGlowShadow = [
    BoxShadow(color: primaryGlow, blurRadius: 20, spreadRadius: 2),
  ];

  static List<BoxShadow> greenGlowShadow = [
    BoxShadow(color: secondaryGlow, blurRadius: 16, spreadRadius: 1),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
