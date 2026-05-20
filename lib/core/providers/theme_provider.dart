import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme provider for managing app light/dark mode
/// Persists theme preference to local storage
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _darkMode = 'dark';
  static const String _lightMode = 'light';
  static const String _systemMode = 'system';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadTheme();
  }

  // ── Getters ────────────────────────────────────────────────────
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  String get themeName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  // ── Load theme from storage ────────────────────────────────────
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? _systemMode;
      _setThemeFromString(savedTheme);
    } catch (_) {
      _setThemeFromString(_systemMode);
    }
  }

  // ── Set theme mode and save to storage ─────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = _themeModeToString(mode);
      await prefs.setString(_themeKey, modeString);
      _themeMode = mode;
      notifyListeners();
    } catch (_) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // ── Helper methods ─────────────────────────────────────────────
  void _setThemeFromString(String theme) {
    _themeMode = switch (theme) {
      _darkMode => ThemeMode.dark,
      _lightMode => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => _darkMode,
      ThemeMode.light => _lightMode,
      ThemeMode.system => _systemMode,
    };
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set to system theme preference
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
}
