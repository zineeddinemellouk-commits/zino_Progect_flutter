import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/providers/locale_provider.dart';
import 'package:test/services/localization_service.dart';

/// Extension for easy access to translations throughout the app
/// Usage: context.tr('key') or context.tr('section.key')
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    final localeProvider = read<LocaleProvider>();
    return LocalizationService.translate(localeProvider.languageCode, key);
  }

  bool get isRtl => read<LocaleProvider>().isRtl;
  String get languageCode => read<LocaleProvider>().languageCode;
}

/// Global translations helper function
/// Usage: t(context, 'key')
String t(BuildContext context, String key) => context.tr(key);
