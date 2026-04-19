# 📖 MIGRATION GUIDE: Making Screens Reactive to Language Changes

## ❌ What's NOT Working (Before Fix)

```dart
// ❌ This screen DOES NOT rebuild when language changes
class DepartmentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Problem: Not watching LanguageProvider
    // When language changes, this screen NEVER rebuilds
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
    );
  }
}
```

---

## ✅ What's NOW Working (After Fix)

### Simple Fix for ANY Screen

Just add **ONE LINE** to watch language changes:

```dart
// ✅ This screen NOW rebuilds when language changes
class DepartmentDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ⚠️ ADD THIS LINE - forces screen to rebuild on language change
    context.watch<LanguageProvider>();

    final l10n = AppLocalizations.of(context);
    // Now when language changes, this screen rebuilds automatically ✅
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
    );
  }
}
```

---

## 🎯 Pattern 1: StatelessWidget (RECOMMENDED)

**Most Common Pattern - Use This**

```dart
import 'package:provider/provider.dart';
import 'package:test/l10n/app_localizations.dart';
import 'package:test/l10n/language_provider.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚠️ CRITICAL: Watch language changes
    context.watch<LanguageProvider>();

    // Get localization after watching
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(
        child: Text(l10n.myContent),
      ),
    );
  }
}
```

---

## 🎯 Pattern 2: StatefulWidget

**For screens with state, add watch in build()**

```dart
import 'package:provider/provider.dart';
import 'package:test/l10n/app_localizations.dart';
import 'package:test/l10n/language_provider.dart';

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  String myData = '';

  @override
  Widget build(BuildContext context) {
    // ⚠️ CRITICAL: Watch language changes even in StatefulWidget
    context.watch<LanguageProvider>();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(
        child: Column(
          children: [
            Text(l10n.myContent),
            Text(myData),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Pattern 3: Using Mixin (OPTIONAL)

**For screens with lots of localization usage**

```dart
import 'package:provider/provider.dart';
import 'package:test/l10n/locale_utils.dart';

class _MyScreenState extends State<MyScreen> with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    watchLang(context); // ⚠️ Watch language changes using mixin
    final l10n = l10nOf(context); // ✅ Clean API

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(
        child: Column(
          children: [
            Text(l10n.content1),
            Text(l10n.content2),
            Text(l10n.content3),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Pattern 4: Using Utility Functions (OPTIONAL)

**For accessing language without watching**

```dart
import 'package:test/l10n/locale_utils.dart';

// Get current language (no watch)
String langCode = getCurrentLanguageCode(context);

// Change language
changeLanguage(context, 'fr');

// Check language
bool isArabic = isCurrentLanguageArabic(context);
```

---

## 📋 MIGRATION CHECKLIST

### For Every Screen That Uses AppLocalizations:

- [ ] **Add import** for `provider/provider.dart` and `language_provider.dart`
- [ ] **Add this line at start of build()**: `context.watch<LanguageProvider>();`
- [ ] **Test**: Change language in Settings, verify screen updates immediately
- [ ] **Verify**: Navigate away and back, language stays the same ✓

### Files That MUST Be Updated

These screens currently use localization but DON'T watch changes:

1. **lib/pages/department_dashboard.dart** → Add `context.watch<LanguageProvider>()`
2. **lib/pages/departement/groups_screen.dart** → Add `context.watch<LanguageProvider>()`
3. **lib/pages/departement/students_screen.dart** → Add `context.watch<LanguageProvider>()`
4. **lib/features/students/presentation/pages/students_page.dart** → Add `context.watch<LanguageProvider>()`
5. **lib/features/teachers/presentation/pages/teacher_profile_page.dart** → Add `context.watch<LanguageProvider>()`
6. **Any other screen using AppLocalizations.of(context)**

---

## 🧪 Testing the Fix

### Before Navigation:

1. Go to Settings → Language
2. Change language (e.g., English → French)
3. ✅ Settings page updates immediately

### After Navigation:

1. Go to Settings → Language → Change to French
2. Navigate to Dashboard (back button or navigation)
3. ✅ Dashboard MUST show French (NEW!)
4. Navigate back to Settings
5. ✅ Language stays French (NEW!)
6. Close and reopen app
7. ✅ Language still French (persistence working)

---

## ⚠️ CRITICAL REQUIREMENTS

### Rule 1: ALWAYS watch before using AppLocalizations

```dart
// ❌ WRONG
final l10n = AppLocalizations.of(context);
return Scaffold(...);

// ✅ CORRECT
context.watch<LanguageProvider>();
final l10n = AppLocalizations.of(context);
return Scaffold(...);
```

### Rule 2: Watch MUST be at start of build()

```dart
// ❌ WRONG - watching too late
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  context.watch<LanguageProvider>(); // Too late!
  return Scaffold(...);
}

// ✅ CORRECT - watch first
@override
Widget build(BuildContext context) {
  context.watch<LanguageProvider>();
  final l10n = AppLocalizations.of(context);
  return Scaffold(...);
}
```

### Rule 3: Every screen using l10n must watch provider

```dart
// If any line uses AppLocalizations.of(context),
// the build() method MUST have:
context.watch<LanguageProvider>();
```

---

## 🔧 Quick Fix Script

If you want to apply the fix to multiple files, search for:

```
AppLocalizations.of(context)
```

And in the build method of that screen, add BEFORE that line:

```dart
context.watch<LanguageProvider>();
```

---

## 📝 Example: DepartmentDashboard (Before → After)

### BEFORE (❌ Broken):

```dart
class DepartmentDashboard extends StatelessWidget {
  const DepartmentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ... rest of code
  }
}
```

### AFTER (✅ Fixed):

```dart
import 'package:provider/provider.dart';
import 'package:test/l10n/language_provider.dart';

class DepartmentDashboard extends StatelessWidget {
  const DepartmentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚠️ THIS LINE IS CRITICAL
    context.watch<LanguageProvider>();

    final l10n = AppLocalizations.of(context);
    // ... rest of code unchanged
  }
}
```

---

## 🚀 Summary

**The One-Line Fix**: Add `context.watch<LanguageProvider>();` to EVERY screen's `build()` method that uses localization.

This ensures:

- ✅ Entire app rebuilds when language changes
- ✅ All screens show updated language instantly
- ✅ Language persists across navigation and app restart
- ✅ Cascade update from Settings to all screens
