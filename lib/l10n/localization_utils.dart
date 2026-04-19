import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/l10n/language_provider.dart';
import 'package:test/l10n/app_localizations.dart';

/// ============================================================================
/// LOCALIZATION UTILITIES - Easy integration for all screens
/// ============================================================================
///
/// This library provides clean patterns for accessing localization and
/// watching language changes in any screen.

/// Mixin for StatefulWidget screens to easily watch language changes
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
///     final l10n = getLocalization(context);
///     return Scaffold(title: Text(l10n.myTitle));
///   }
/// }
/// ```
mixin LocalizationMixin<T extends StatefulWidget> on State<T> {
  /// Get localization instance
  AppLocalizations getLocalization(BuildContext context) {
    return AppLocalizations.of(context);
  }

  /// Get language provider and watch for changes
  /// This automatically rebuilds when language changes
  LanguageProvider watchLanguage(BuildContext context) {
    return context.watch<LanguageProvider>();
  }

  /// Get language provider without watching
  LanguageProvider readLanguage(BuildContext context) {
    return context.read<LanguageProvider>();
  }

  /// Check if current language is Arabic
  bool isArabic(BuildContext context) {
    return context.read<LanguageProvider>().isArabic;
  }

  /// Get current language code
  String getLanguageCode(BuildContext context) {
    return context.read<LanguageProvider>().languageCode;
  }

  /// Change language and persist
  Future<void> changeLanguage(
    BuildContext context,
    String languageCode, {
    Function? onSuccess,
  }) async {
    try {
      context.read<LanguageProvider>().setLanguage(languageCode);
      onSuccess?.call();
      debugPrint('✅ Language changed to: $languageCode');
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
    }
  }
}

/// Utility functions for StatelessWidget or to access from any context

/// Get localization without watching (read-only)
AppLocalizations getLocalization(BuildContext context) {
  return AppLocalizations.of(context);
}

/// Watch language provider and rebuild on change
/// Use this in StatelessWidget build() method
LanguageProvider watchLanguage(BuildContext context) {
  return context.watch<LanguageProvider>();
}

/// Read language provider without watching
LanguageProvider readLanguage(BuildContext context) {
  return context.read<LanguageProvider>();
}

/// Check if current language is Arabic
bool isArabic(BuildContext context) {
  return context.read<LanguageProvider>().isArabic;
}

/// Check if current language is French
bool isFrench(BuildContext context) {
  return context.read<LanguageProvider>().isFrench;
}

/// Check if current language is English
bool isEnglish(BuildContext context) {
  return context.read<LanguageProvider>().isEnglish;
}

/// Get current language code
String getLanguageCode(BuildContext context) {
  return context.read<LanguageProvider>().languageCode;
}

/// Get text direction based on language
TextDirection getTextDirection(BuildContext context) {
  return context.read<LanguageProvider>().textDirection;
}

/// ============================================================================
/// SCREEN PATTERNS - Copy-paste ready implementations
/// ============================================================================

/// Pattern 1: StatelessWidget with localization watching
///
/// ```dart
/// class MyStatelessScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // ✅ Watch language changes
///     watchLanguage(context);
///
///     final l10n = getLocalization(context);
///     return Scaffold(title: Text(l10n.myTitle));
///   }
/// }
/// ```

/// Pattern 2: StatefulWidget with mixin
///
/// ```dart
/// class MyStatefulScreen extends StatefulWidget {
///   @override
///   State<MyStatefulScreen> createState() => _MyStatefulScreenState();
/// }
///
/// class _MyStatefulScreenState extends State<MyStatefulScreen>
///     with LocalizationMixin {
///   @override
///   Widget build(BuildContext context) {
///     watchLanguage(context); // ✅ Watch for language changes
///     final l10n = getLocalization(context);
///     return Scaffold(title: Text(l10n.myTitle));
///   }
/// }
/// ```

/// Pattern 3: Direct usage in any widget
///
/// ```dart
/// class MyCustomWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Text(
///       getLocalization(context).myTitle,
///       // ✅ When you need localization + watching
///     );
///   }
/// }
/// ```
