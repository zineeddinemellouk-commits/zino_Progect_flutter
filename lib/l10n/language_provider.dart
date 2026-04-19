import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<Locale> appSupportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('ar'),
];

const Locale appDefaultLocale = Locale('en');

/// ✅ SINGLE SOURCE OF TRUTH for language state + persistence
/// This provider:
/// - Manages language state reactively
/// - Persists to SharedPreferences internally (no separate service)
/// - Ensures all screens update when language changes
/// - Is initialized ONCE at app startup
class LanguageProvider extends ChangeNotifier {
  Locale _locale = appDefaultLocale;
  late SharedPreferences _prefs;
  bool _initialized = false;

  static const String _languageKey = 'app_language_code';

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isFrench => _locale.languageCode == 'fr';
  bool get isEnglish => _locale.languageCode == 'en';

  /// Returns TextDirection based on language (RTL for Arabic, LTR for others)
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  /// Get localized language name
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Initialize provider with SharedPreferences and load saved language
  /// ⚠️ CALL THIS ONCE in main() before runApp()
  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load saved language from storage
    final savedCode = _prefs.getString(_languageKey) ?? 'en';
    if (appSupportedLocales.any((l) => l.languageCode == savedCode)) {
      _locale = Locale(savedCode);
    } else {
      _locale = appDefaultLocale;
    }

    _initialized = true;
    debugPrint(
      '🌐 LanguageProvider initialized with locale: ${_locale.languageCode}',
    );
  }

  /// Set language by code, persist to SharedPreferences, notify all listeners
  /// This is the ONLY way to change language globally
  ///
  /// Flow:
  /// 1. Update local _locale
  /// 2. Persist to SharedPreferences (async, but doesn't block UI)
  /// 3. Notify all listeners (triggers MaterialApp rebuild via Consumer)
  /// 4. MaterialApp rebuilds with new locale
  /// 5. All dependent screens rebuild automatically
  void setLanguage(String languageCode) {
    assert(_initialized, 'LanguageProvider must call initialize() first');

    if (!appSupportedLocales.any((l) => l.languageCode == languageCode)) {
      debugPrint('⚠️ Unsupported language: $languageCode');
      return;
    }

    if (_locale.languageCode == languageCode) {
      // Already this language, but still force rebuild to refresh delegates
      notifyListeners();
      return;
    }

    _locale = Locale(languageCode);

    // Persist asynchronously (non-blocking)
    _prefs.setString(_languageKey, languageCode).then((_) {
      debugPrint('💾 Language persisted: $languageCode');
    });

    // CRITICAL: Notify listeners immediately (before persistence completes)
    // This ensures UI updates instantly
    notifyListeners();
    debugPrint('🌐 Language changed to: $languageCode');
  }

  /// Shorthand setters for common languages
  void setEnglish() => setLanguage('en');
  void setFrench() => setLanguage('fr');
  void setArabic() => setLanguage('ar');
}
