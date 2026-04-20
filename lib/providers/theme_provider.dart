import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global theme provider for managing dark mode and light mode for department accounts
/// Handles theme persistence using SharedPreferences
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'department_theme_mode';
  static const String _defaultTheme = 'light';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
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
      default:
        return 'System';
    }
  }

  // ── Load theme from storage ────────────────────────────────────
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? _defaultTheme;
      _setThemeFromCode(savedTheme);
    } catch (_) {
      _setThemeFromCode(_defaultTheme);
    }
  }

  // ── Toggle theme ──────────────────────────────────────────────
  Future<void> toggleTheme() async {
    final newTheme = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newTheme);
  }

  // ── Set theme mode and save to storage ─────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = mode == ThemeMode.dark ? 'dark' : 'light';
      await prefs.setString(_themeKey, themeString);
      _setThemeFromCode(themeString);
    } catch (_) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // ── Internal theme setter ──────────────────────────────────────
  void _setThemeFromCode(String themeCode) {
    final code = themeCode.toLowerCase();
    _themeMode = code == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ── Get all theme options ──────────────────────────────────────
  static Map<String, ThemeMode> get themeOptions => {
    'Light': ThemeMode.light,
    'Dark': ThemeMode.dark,
  };
}
