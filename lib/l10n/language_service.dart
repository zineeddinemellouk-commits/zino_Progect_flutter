import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Service responsible for language persistence and retrieval
class LanguageService {
  static const String _languageKey = 'app_language_code';
  static const String _defaultLanguage = 'en';
  static const List<String> _supportedLanguages = ['en', 'fr', 'ar'];

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the service (call once during app startup)
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Get the saved language code, or default
  String getSavedLanguage() {
    assert(_initialized, 'LanguageService must be initialized first');
    final saved = _prefs.getString(_languageKey) ?? _defaultLanguage;
    return _supportedLanguages.contains(saved) ? saved : _defaultLanguage;
  }

  /// Save language preference
  Future<void> saveLanguage(String languageCode) async {
    assert(_initialized, 'LanguageService must be initialized first');
    if (!_supportedLanguages.contains(languageCode)) {
      debugPrint(
        'Warning: Unsupported language code: $languageCode. '
        'Using default: $_defaultLanguage',
      );
      return;
    }
    await _prefs.setString(_languageKey, languageCode);
  }

  /// Validate language code
  static bool isSupported(String code) => _supportedLanguages.contains(code);
}
