# Localization Quick Reference

## Before vs After

### ❌ OLD WAY (Problematic)

```dart
// main.dart - OLD (loses language on restart)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);
  runApp(const MyApp()); // ❌ Language not loaded
}

class MyApp... {
  ChangeNotifierProvider(
    create: (_) => LanguageProvider(), // ❌ Default locale only
  ),
}

// Settings - OLD (saves only to Firestore, slow)
void _changeLanguage(String code) async {
  context.read<LanguageProvider>().setLanguage(code); // ✅ Instant UI

  // ❌ Slow Firestore call, user sees delay before language sticks
  await firestore.collection('user_profiles').doc(uid).set({
    'language': code,
  });
}
```

---

### ✅ NEW WAY (Recommended)

```dart
// main.dart - NEW (instant startup + persistence)
late LanguageService _languageService;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);

  // ✅ Initialize language service (fast, local)
  _languageService = LanguageService();
  await _languageService.initialize();

  runApp(const MyApp());
}

class MyApp... {
  ChangeNotifierProvider(
    create: (_) => LanguageProvider()
      ..initializeWithSavedLanguage(
        _languageService.getSavedLanguage(), // ✅ Restored
      ),
  ),
}

// Settings - NEW (instant + dual persistence)
void _changeLanguage(String code) async {
  context.read<LanguageProvider>().setLanguage(code); // ✅ Instant UI

  // ✅ Dual save: fast local + cloud sync
  await _languageService.saveLanguage(code); // ~10ms

  await firestore.collection('user_profiles').doc(uid).set({
    'language': code,
  }); // Async, non-blocking
}
```

---

## Common Patterns

### Pattern 1: Change Language (Settings Page)

```dart
// Language button in UI
_langButton(
  label: 'EN',
  isSelected: context.watch<LanguageProvider>().languageCode == 'en',
  onTap: () {
    // Instant UI update
    context.read<LanguageProvider>().setEnglish();
  },
)

// Save when user clicks "Save Profile"
await _languageService.saveLanguage(
  context.read<LanguageProvider>().languageCode
);
```

### Pattern 2: Display Localized Text

```dart
// Get localizations
final l10n = AppLocalizations.of(context);

// Use in UI
Text(l10n.appName)           // 'Hodoori' or 'حضوري'
Text(l10n.departmentSettings) // etc.
```

### Pattern 3: Handle RTL Layout

```dart
// Read text direction from provider
final provider = context.watch<LanguageProvider>();

// Use in UI
Directionality(
  textDirection: provider.textDirection, // RTL for Arabic
  child: Row(
    children: [...],
  ),
)

// Or use in single widget
Text('content', textDirection: provider.textDirection)
```

### Pattern 4: Check Current Language

```dart
final provider = context.read<LanguageProvider>();

if (provider.isArabic) {
  // Do something for Arabic
}

if (provider.isFrench) {
  // Do something for French
}

// Get language name
String name = provider.currentLanguageName; // 'English', 'Français', 'العربية'
```

---

## API Reference

### LanguageService

```dart
// Initialize (call once in main())
await _languageService.initialize();

// Get saved language (instant, no async)
String code = _languageService.getSavedLanguage();

// Save language
await _languageService.saveLanguage('ar');

// Check if language is supported
bool isOk = LanguageService.isSupported('fr'); // true
bool isBad = LanguageService.isSupported('de'); // false
```

### LanguageProvider

```dart
// Get properties
String code = provider.languageCode;
Locale locale = provider.locale;
TextDirection dir = provider.textDirection;
String name = provider.currentLanguageName;

// Setters
provider.setLanguage('en');
provider.setEnglish();
provider.setFrench();
provider.setArabic();

// Checks
bool isArabic = provider.isArabic;
bool isFrench = provider.isFrench;
bool isEnglish = provider.isEnglish;

// Initialize (call in main, before build)
provider.initializeWithSavedLanguage('ar');

// Notify listeners manually (rarely needed)
provider.notifyListeners();
```

### AppLocalizations

```dart
// Get instance
final l10n = AppLocalizations.of(context);

// Access translations
l10n.appName
l10n.save
l10n.cancel
l10n.settings
l10n.language
// ... (all strings in _translations map)

// Custom translation
String text = l10n.translate('customKey'); // Returns translation or key
```

---

## Setup Checklist

- [ ] Add `shared_preferences` to pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Create `lib/l10n/language_service.dart`
- [ ] Create `lib/l10n/language_provider.dart`
- [ ] Update `lib/l10n/app_localizations.dart`
- [ ] Update `lib/main.dart` with LanguageService init
- [ ] Update DepartmentSettingsPage
- [ ] Test language switching works
- [ ] Test language persists after app restart
- [ ] Test Arabic shows RTL
- [ ] Test offline mode

---

## Debugging

### Check Saved Language

```dart
// In debug console
final prefs = await SharedPreferences.getInstance();
print(prefs.getString('app_language_code')); // Should print 'en', 'fr', or 'ar'
```

### Verify Provider State

```dart
// In widget build
final provider = context.watch<LanguageProvider>();
debugPrint('Current language: ${provider.languageCode}');
debugPrint('Is Arabic: ${provider.isArabic}');
debugPrint('Text direction: ${provider.textDirection}');
```

### Check Translations

```dart
// Verify all keys exist
final l10n = AppLocalizations.of(context);
final missingKeys = [];
// Add assertions for commonly used keys
assert(l10n.appName.isNotEmpty, 'appName missing');
assert(l10n.save.isNotEmpty, 'save missing');
```

---

## Performance Tips

1. **Don't call LanguageService multiple times**

   ```dart
   // ❌ BAD - Multiple initializations
   main() async {
     for(i in 0..10) await LanguageService().initialize();
   }

   // ✅ GOOD - Single global instance
   late LanguageService _languageService;
   main() async {
     _languageService = LanguageService();
     await _languageService.initialize();
   }
   ```

2. **Use Consumer sparingly for UI updates**

   ```dart
   // ✅ GOOD - Only rebuild language selector
   Consumer<LanguageProvider>(
     builder: (_, provider, __) => _buildLanguageSelector(provider),
   )

   // ❌ BAD - Rebuilds entire page
   Consumer<LanguageProvider>(
     builder: (_, provider, __) => Scaffold(body: ...), // Too much
   )
   ```

3. **Cache AppLocalizations if used frequently**

   ```dart
   // In widget
   late AppLocalizations l10n;

   @override
   void initState() {
     super.initState();
     l10n = AppLocalizations.of(context);
   }
   ```

---

## Troubleshooting

| Problem                            | Solution                                                              |
| ---------------------------------- | --------------------------------------------------------------------- |
| Language not persisting            | Check `LanguageService.initialize()` called in main()                 |
| Settings page shows wrong language | Use `context.watch<>` not `context.read<>`                            |
| Arabic not RTL                     | Wrap with `Directionality(textDirection: provider.textDirection)`     |
| Slow app startup                   | Ensure using SharedPreferences, not Firestore for initial load        |
| Translations showing as keys       | Check AppLocalizations.of(context) and verify delegate in MaterialApp |
| Multiple rebuilds                  | Use Consumer pattern, not watch in build                              |

---

## Links

- **Full Documentation:** See `LOCALIZATION_IMPROVEMENTS.md`
- **Provider Examples:** https://pub.dev/packages/provider/example
- **Flutter i18n:** https://docs.flutter.dev/accessibility-and-localization/internationalization
