import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global locale provider for managing app language and RTL support
/// Supports: English, French, Arabic
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  static const String _defaultLocale = 'en';

  Locale _currentLocale = const Locale('en');
  bool _isRtl = false;

  LocaleProvider() {
    _loadLocale();
  }

  // ── Getters ────────────────────────────────────────────────────
  Locale get currentLocale => _currentLocale;
  bool get isRtl => _isRtl;
  String get languageCode => _currentLocale.languageCode;
  String get languageName {
    switch (_currentLocale.languageCode) {
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  // ── Load locale from storage ───────────────────────────────────
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey) ?? _defaultLocale;
      _setLocaleFromCode(savedLocale);
    } catch (_) {
      _setLocaleFromCode(_defaultLocale);
    }
  }

  // ── Set locale and save to storage ─────────────────────────────
  Future<void> setLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      _setLocaleFromCode(languageCode);
    } catch (_) {
      _setLocaleFromCode(languageCode);
    }
  }

  // ── Internal locale setter ─────────────────────────────────────
  void _setLocaleFromCode(String languageCode) {
    final code = languageCode.toLowerCase();
    _currentLocale = Locale(code);
    _isRtl = code == 'ar';
    notifyListeners();
  }

  // ── Get all supported locales ──────────────────────────────────
  static List<Locale> get supportedLocales => const [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
  ];

  // ── Get all language options ───────────────────────────────────
  static Map<String, String> get languageOptions => {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
  };
}
