import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/l10n/app_localizations.dart';
import 'package:test/l10n/language_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🌐 GLOBAL LOCALIZATION UTILITIES
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This file provides clean APIs for all screens to:
/// 1. Access current localization (AppLocalizations)
/// 2. Watch language changes and rebuild
/// 3. Get current language info
/// 4. Change language programmatically

/// Get current AppLocalizations from context
///
/// Usage in any screen:
/// ```dart
/// final l10n = getAppLocalizations(context);
/// Text(l10n.settings)
/// ```
AppLocalizations getAppLocalizations(BuildContext context) {
  return AppLocalizations.of(context);
}

/// Get current LanguageProvider from context (without watching)
///
/// Usage when you need current language info:
/// ```dart
/// final langProvider = readLanguageProvider(context);
/// print(langProvider.languageCode); // 'en', 'fr', 'ar'
/// ```
LanguageProvider readLanguageProvider(BuildContext context) {
  return context.read<LanguageProvider>();
}

/// Watch LanguageProvider and rebuild when language changes
///
/// ⚠️ IMPORTANT: Use this in your screen's build method to ensure
/// the screen rebuilds when language changes!
///
/// Usage in StatelessWidget:
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     context.watch<LanguageProvider>(); // ← THIS LINE IS CRITICAL
///     final l10n = AppLocalizations.of(context);
///     return Scaffold(
///       title: l10n.myTitle,
///     );
///   }
/// }
/// ```
///
/// Usage in StatefulWidget:
/// ```dart
/// class _MyScreenState extends State<MyScreen> {
///   @override
///   Widget build(BuildContext context) {
///     context.watch<LanguageProvider>(); // ← THIS LINE IS CRITICAL
///     final l10n = AppLocalizations.of(context);
///     return Scaffold(
///       title: l10n.myTitle,
///     );
///   }
/// }
/// ```
LanguageProvider watchLanguageProvider(BuildContext context) {
  return context.watch<LanguageProvider>();
}

/// Change language programmatically from anywhere
///
/// Usage:
/// ```dart
/// changeLanguage(context, 'fr'); // Change to French
/// ```
void changeLanguage(BuildContext context, String languageCode) {
  context.read<LanguageProvider>().setLanguage(languageCode);
}

/// Change language to English
void setLanguageToEnglish(BuildContext context) {
  context.read<LanguageProvider>().setEnglish();
}

/// Change language to French
void setLanguageToFrench(BuildContext context) {
  context.read<LanguageProvider>().setFrench();
}

/// Change language to Arabic
void setLanguageToArabic(BuildContext context) {
  context.read<LanguageProvider>().setArabic();
}

/// Get current language code ('en', 'fr', 'ar')
String getCurrentLanguageCode(BuildContext context) {
  return context.read<LanguageProvider>().languageCode;
}

/// Get current language name for display ('English', 'Français', 'العربية')
String getCurrentLanguageName(BuildContext context) {
  return context.read<LanguageProvider>().currentLanguageName;
}

/// Check if current language is Arabic (for RTL handling)
bool isCurrentLanguageArabic(BuildContext context) {
  return context.read<LanguageProvider>().isArabic;
}

/// Check if current language is French
bool isCurrentLanguageFrench(BuildContext context) {
  return context.read<LanguageProvider>().isFrench;
}

/// Check if current language is English
bool isCurrentLanguageEnglish(BuildContext context) {
  return context.read<LanguageProvider>().isEnglish;
}

/// Get text direction based on current language
TextDirection getCurrentTextDirection(BuildContext context) {
  return context.read<LanguageProvider>().textDirection;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 🔧 MIXIN FOR STATEFUL WIDGETS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Alternative approach: Use this mixin in your StatefulWidget if you prefer
///
/// Usage:
/// ```dart
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> with LocalizationMixin {
///   @override
///   Widget build(BuildContext context) {
///     final l10n = l10nOf(context); // Using mixin helper
///     return Scaffold(
///       title: l10n.myTitle,
///     );
///   }
/// }
/// ```
mixin LocalizationMixin {
  /// Get AppLocalizations from context
  AppLocalizations l10nOf(BuildContext context) {
    return AppLocalizations.of(context);
  }

  /// Get LanguageProvider from context
  LanguageProvider langOf(BuildContext context) {
    return context.read<LanguageProvider>();
  }

  /// Watch language changes
  LanguageProvider watchLang(BuildContext context) {
    return context.watch<LanguageProvider>();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// 📋 QUICK REFERENCE FOR COMMON PATTERNS
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Pattern 1: Simple StatelessWidget with localization
/// ─────────────────────────────────────────────────
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     context.watch<LanguageProvider>(); // ⚠️ CRITICAL: Watch for changes
///     final l10n = AppLocalizations.of(context);
///     return Scaffold(
///       appBar: AppBar(title: Text(l10n.myTitle)),
///     );
///   }
/// }
///
/// Pattern 2: StatefulWidget with localization
/// ─────────────────────────────────────────────
/// class MyScreen extends StatefulWidget {
///   @override
///   State<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends State<MyScreen> {
///   @override
///   Widget build(BuildContext context) {
///     context.watch<LanguageProvider>(); // ⚠️ CRITICAL: Watch for changes
///     final l10n = AppLocalizations.of(context);
///     return Scaffold(
///       appBar: AppBar(title: Text(l10n.myTitle)),
///     );
///   }
/// }
///
/// Pattern 3: Using the mixin
/// ──────────────────────────
/// class _MyScreenState extends State<MyScreen> with LocalizationMixin {
///   @override
///   Widget build(BuildContext context) {
///     watchLang(context); // ⚠️ CRITICAL: Watch for changes
///     final l10n = l10nOf(context);
///     return Scaffold(
///       appBar: AppBar(title: Text(l10n.myTitle)),
///     );
///   }
/// }
/// 
/// ═══════════════════════════════════════════════════════════════════════════
