# 💻 CONCRETE CODE EXAMPLES - Before & After

## Example 1: Simple StatelessWidget (Dashboard)

### ❌ BEFORE (Language doesn't update)

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Problem: No watch = no rebuild on language change
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),  // Stuck in English
      ),
      body: Text(l10n.welcome),  // Stuck in English
    );
  }
}
```

**Problem:** When language changes in Settings:

1. LanguageProvider notifies listeners
2. Dashboard is NOT listening
3. build() is NOT called
4. Old English text remains

### ✅ AFTER (Language updates automatically)

```dart
import 'package:provider/provider.dart';  // ADD IMPORT
import 'package:test/l10n/language_provider.dart';  // ADD IMPORT

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ADD THIS ONE LINE:
    context.watch<LanguageProvider>();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),  // ✅ Updates to French
      ),
      body: Text(l10n.welcome),  // ✅ Updates to French
    );
  }
}
```

**Result:** When language changes:

1. LanguageProvider notifies all listeners
2. Dashboard IS listening (via watch())
3. build() is called
4. AppLocalizations.of() called again
5. New French text appears instantly ✅

---

## Example 2: StatefulWidget (Teacher Profile Page)

### ❌ BEFORE (Broken language updates)

```dart
class TeacherProfilePage extends StatefulWidget {
  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  late TeacherData _teacher;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  @override
  Widget build(BuildContext context) {
    // Problem: No watch = language changes ignored
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherProfile)),  // ❌ Won't update
      body: Column(
        children: [
          Text(_teacher.name),
          Text(l10n.email),  // ❌ Won't update
          Text(_teacher.email),
        ],
      ),
    );
  }
}
```

### ✅ AFTER (With mixin for cleaner code)

```dart
import 'package:test/l10n/localization_utils.dart';  // ADD IMPORT

class TeacherProfilePage extends StatefulWidget {
  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

// ADD MIXIN
class _TeacherProfilePageState extends State<TeacherProfilePage>
    with LocalizationMixin {

  late TeacherData _teacher;

  @override
  void initState() {
    super.initState();
    _loadTeacher();
  }

  @override
  Widget build(BuildContext context) {
    // ADD THIS LINE (mixin method):
    watchLanguage(context);

    // USE MIXIN METHOD (cleaner):
    final l10n = getLocalization(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teacherProfile)),  // ✅ Updates
      body: Column(
        children: [
          Text(_teacher.name),
          Text(l10n.email),  // ✅ Updates
          Text(_teacher.email),
        ],
      ),
    );
  }
}
```

**Benefit:** Mixin provides clean API:

- `watchLanguage(context)` - Watch for changes
- `getLocalization(context)` - Get translations
- `isArabic(context)` - Check language
- All in one mixin ✅

---

## Example 3: Complex StatefulWidget (Students Page with RTL)

### ❌ BEFORE (Broken language & RTL)

```dart
class StudentsPage extends StatefulWidget {
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Student> students = [];

  @override
  Widget build(BuildContext context) {
    // Problem: No language watching
    final l10n = AppLocalizations.of(context);

    // Problem: RTL not handled
    return Scaffold(
      appBar: AppBar(title: Text(l10n.students)),
      body: ListView(
        children: students.map((s) => Text(s.name)).toList(),
      ),
    );
  }
}
```

### ✅ AFTER (With language watching & RTL support)

```dart
import 'package:test/l10n/localization_utils.dart';

class StudentsPage extends StatefulWidget {
  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage>
    with LocalizationMixin {

  List<Student> students = [];

  @override
  Widget build(BuildContext context) {
    // ADD THIS LINE (watch language):
    watchLanguage(context);

    final l10n = getLocalization(context);

    // ADD RTL SUPPORT:
    if (isArabic(context)) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: _buildScaffold(l10n),
      );
    }

    return _buildScaffold(l10n);
  }

  Widget _buildScaffold(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.students)),  // ✅ Updates
      body: ListView(
        children: students.map((s) => Text(s.name)).toList(),
      ),
    );
  }
}
```

**Improvements:**

1. ✅ Watches language changes
2. ✅ RTL handled for Arabic
3. ✅ Cleaner code with extracted \_buildScaffold()
4. ✅ All students see translations in their language

---

## Example 4: StreamBuilder with Language Updates

### ❌ BEFORE (StreamBuilder loses language context)

```dart
class StudentAbsenceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Problem: StreamBuilder might use cached context
    return StreamBuilder<List<Absence>>(
      stream: getAbsenceStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LoadingWidget();

        // ❌ Language might not update
        final l10n = AppLocalizations.of(context);

        return ListView(
          children: snapshot.data!.map((absence) {
            return ListTile(
              title: Text(l10n.absence),  // ❌ Won't update in builder
              subtitle: Text(absence.date),
            );
          }).toList(),
        );
      },
    );
  }
}
```

### ✅ AFTER (StreamBuilder with language watching)

```dart
import 'package:test/l10n/localization_utils.dart';

class StudentAbsenceList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ ADD WATCH FIRST:
    watchLanguage(context);

    return StreamBuilder<List<Absence>>(
      stream: getAbsenceStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LoadingWidget();

        // ✅ NOW get localization:
        final l10n = getLocalization(context);

        return ListView(
          children: snapshot.data!.map((absence) {
            return ListTile(
              title: Text(l10n.absence),  // ✅ Updates properly
              subtitle: Text(absence.date),
            );
          }).toList(),
        );
      },
    );
  }
}
```

**Key Point:** Call `watchLanguage()` BEFORE StreamBuilder, so the screen rebuilds when language changes AND when stream updates.

---

## Example 5: Settings Page (Already Correct - For Reference)

### ✅ How Settings Page Should Look

```dart
class DepartmentSettingsPage extends StatefulWidget {
  @override
  State<DepartmentSettingsPage> createState() => _DepartmentSettingsPageState();
}

class _DepartmentSettingsPageState extends State<DepartmentSettingsPage> {
  late LanguageService _languageService;

  @override
  void initState() {
    super.initState();
    _languageService = LanguageService();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ALREADY WATCHING (this is what we need everywhere)
    final languageProvider = context.watch<LanguageProvider>();

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Column(
        children: [
          // Language buttons
          Row(
            children: [
              _langButton(
                label: 'EN',
                isSelected: languageProvider.languageCode == 'en',
                onTap: () async {
                  // ✅ Update provider
                  context.read<LanguageProvider>().setEnglish();
                  // ✅ Persist to storage
                  await _languageService.saveLanguage('en');
                },
              ),
              _langButton(
                label: 'FR',
                isSelected: languageProvider.languageCode == 'fr',
                onTap: () async {
                  context.read<LanguageProvider>().setFrench();
                  await _languageService.saveLanguage('fr');
                },
              ),
              _langButton(
                label: 'ع',
                isSelected: languageProvider.languageCode == 'ar',
                onTap: () async {
                  context.read<LanguageProvider>().setArabic();
                  await _languageService.saveLanguage('ar');
                },
              ),
            ],
          ),
          // Other settings...
        ],
      ),
    );
  }

  Widget _langButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Button implementation...
    return Container();
  }
}
```

---

## Example 6: Using Utility Functions (Alternative to Mixin)

### ✅ Using Utility Functions

```dart
import 'package:test/l10n/localization_utils.dart';

class ClassesListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Watch language
    watchLanguage(context);

    // Get localization
    final l10n = getLocalization(context);

    // Check language
    if (isArabic(context)) {
      return _buildArabicUI(l10n);
    }

    if (isFrench(context)) {
      return _buildFrenchUI(l10n);
    }

    // Default to English
    return _buildEnglishUI(l10n);
  }

  Widget _buildArabicUI(AppLocalizations l10n) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.classes)),
        body: Center(child: Text(l10n.welcomeMessage)),
      ),
    );
  }

  Widget _buildFrenchUI(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.classes)),
      body: Center(child: Text(l10n.welcomeMessage)),
    );
  }

  Widget _buildEnglishUI(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.classes)),
      body: Center(child: Text(l10n.welcomeMessage)),
    );
  }
}
```

---

## Pattern Selection Guide

| Scenario                  | Use This                           | Why                     |
| ------------------------- | ---------------------------------- | ----------------------- |
| Simple StatelessWidget    | Direct `context.watch()`           | Cleanest & shortest     |
| StatefulWidget            | Use mixin `LocalizationMixin`      | Provides helper methods |
| Complex logic             | Utility functions                  | More readable           |
| Many language-specific UI | Utility functions                  | Easier to organize      |
| RTL handling              | Utility functions + Directionality | Separate concerns       |

---

## Quick Copy-Paste Templates

### Template 1: StatelessWidget (Copy & Use)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/l10n/language_provider.dart';
import 'package:test/l10n/app_localizations.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(child: Text(l10n.myContent)),
    );
  }
}
```

### Template 2: StatefulWidget with Mixin (Copy & Use)

```dart
import 'package:flutter/material.dart';
import 'package:test/l10n/localization_utils.dart';
import 'package:test/l10n/app_localizations.dart';

class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> with LocalizationMixin {
  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final l10n = getLocalization(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(child: Text(l10n.myContent)),
    );
  }
}
```

### Template 3: With RTL Support (Copy & Use)

```dart
import 'package:test/l10n/localization_utils.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    watchLanguage(context);
    final l10n = getLocalization(context);

    Widget content = Scaffold(
      appBar: AppBar(title: Text(l10n.myTitle)),
      body: Center(child: Text(l10n.myContent)),
    );

    if (isArabic(context)) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: content,
      );
    }

    return content;
  }
}
```

---

## ✅ Before & After Comparison

| Aspect           | Before ❌      | After ✅           |
| ---------------- | -------------- | ------------------ |
| Code change      | None (broken)  | +1 line per screen |
| Language updates | Only Settings  | All screens ✅     |
| User logout      | Yes (broken)   | No ✅              |
| Navigation       | Broken         | Works ✅           |
| Persistence      | Broken         | Yes ✅             |
| Lines of code    | ~2000          | ~2000 (same)       |
| Code quality     | Mixed concerns | Separated ✅       |
| Maintenance      | Hard           | Easy ✅            |

---

## 🎯 Implementation Checklist Per Screen

For each screen, verify:

```
☐ Found file using AppLocalizations.of()
☐ Added import (if needed)
☐ Added context.watch<LanguageProvider>() in build()
☐ No compilation errors
☐ App builds successfully
☐ Screen compiles without warnings
```

---

## 🚀 Ready to Start?

Pick any of these templates and:

1. Copy the code
2. Replace YOUR_SCREEN_NAME with actual name
3. Update imports
4. Test

That's it! One line changes everything. ✅
