import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_initialThemeMode());

  static ThemeMode _initialThemeMode() {
    final prefs = LocalStorage.instance.prefs;
    final themeString = prefs.getString('theme_mode');
    if (themeString == 'light') return ThemeMode.light;
    if (themeString == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void toggleTheme() {
    // Si es system, en Android usualmente es light, pero vamos a togglear
    if (state == ThemeMode.dark) {
      setTheme(ThemeMode.light);
    } else {
      setTheme(ThemeMode.dark);
    }
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    final prefs = LocalStorage.instance.prefs;
    prefs.setString('theme_mode', mode.name);
  }
}
