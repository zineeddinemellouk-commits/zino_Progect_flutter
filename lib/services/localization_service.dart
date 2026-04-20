import 'dart:convert';
import 'package:flutter/services.dart';

/// Localization service for loading and managing translations
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  static Map<String, Map<String, String>> _translations = {};

  factory LocalizationService() {
    return _instance;
  }

  LocalizationService._internal();

  // ── Initialize translations ────────────────────────────────────
  static Future<void> init() async {
    await Future.wait([
      _loadLocale('en'),
      _loadLocale('fr'),
      _loadLocale('ar'),
    ]);
  }

  // ── Load single locale file ────────────────────────────────────
  static Future<void> _loadLocale(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/l10n/${languageCode}.json',
      );
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      _translations[languageCode] = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      print('Error loading locale $languageCode: $e');
      _translations[languageCode] = {};
    }
  }

  // ── Get translation by key ─────────────────────────────────────
  static String translate(String languageCode, String key) {
    if (!_translations.containsKey(languageCode)) {
      return key;
    }
    return _translations[languageCode]?[key] ?? key;
  }

  // ── Get all translations for a language ────────────────────────
  static Map<String, String> getTranslations(String languageCode) {
    return _translations[languageCode] ?? {};
  }

  // ── Clear cache (useful for testing) ───────────────────────────
  static void clearCache() {
    _translations.clear();
  }
}
