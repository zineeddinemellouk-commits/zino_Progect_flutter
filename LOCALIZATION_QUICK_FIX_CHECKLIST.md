# 🎯 QUICK REFERENCE: Using LanguageProvider in All Screens

## Pattern to Use in ALL Screens

### ✅ CORRECT: Get current language

```dart
// In any screen/page
final languageCode = context.read<LanguageProvider>().languageCode;
// Returns: 'en', 'fr', or 'ar'
```

### ✅ CORRECT: Watch language changes

```dart
// In widget's build method
final languageProvider = context.watch<LanguageProvider>();

// Use properties:
if (languageProvider.isArabic) { /* RTL layout */ }
if (languageProvider.isFrench) { /* French-specific */ }
if (languageProvider.isEnglish) { /* English-specific */ }
```

### ✅ CORRECT: Change language

```dart
// Only in Settings page or language selector
context.read<LanguageProvider>().setEnglish();
context.read<LanguageProvider>().setFrench();
context.read<LanguageProvider>().setArabic();
// OR:
context.read<LanguageProvider>().setLanguage('en');
```

### ✅ CORRECT: Get text direction (for RTL)

```dart
final direction = context.read<LanguageProvider>().textDirection;
// Returns: TextDirection.rtl (for Arabic) or TextDirection.ltr (for others)

// Use in Directionality widget:
Directionality(
  textDirection: direction,
  child: MyWidget(),
)
```

---

## ❌ DO NOT DO THESE

### ❌ WRONG: Import languageService from main.dart

```dart
// ❌ DON'T
import 'package:test/main.dart' show languageService;
await languageService.saveLanguage('en');
```

### ❌ WRONG: Create LanguageService instance

```dart
// ❌ DON'T
final _languageService = LanguageService();
await _languageService.initialize();
```

### ❌ WRONG: Set language in initState

```dart
// ❌ DON'T - This resets language on every screen open
@override
void initState() {
  super.initState();
  context.read<LanguageProvider>().setLanguage('en');  // ❌ NO!
}
```

### ❌ WRONG: Set language in \_loadUserProfile

```dart
// ❌ DON'T - This resets language when loading profile
Future<void> _loadUserProfile() async {
  final data = await firestore.collection('user_profiles').get();
  context.read<LanguageProvider>().setLanguage(data['language']);  // ❌ NO!
}
```

### ❌ WRONG: Multiple language management

```dart
// ❌ DON'T - Only use ONE method
context.read<LanguageProvider>().setEnglish();  // ✅ This one
await languageService.saveLanguage('en');      // ❌ Don't also do this
```

---

## 📋 CHECKLIST: Update Each Screen

If you have other screens showing language inconsistencies:

- [ ] **Remove** any `import 'package:test/main.dart' show languageService;`
- [ ] **Remove** any `final _languageService = LanguageService();`
- [ ] **Remove** any `await languageService.initialize();`
- [ ] **Remove** any `await languageService.saveLanguage();`
- [ ] **Remove** any manual `setLanguage()` calls in `initState()` or `_loadUserProfile()`
- [ ] **Replace** all with `context.read<LanguageProvider>().languageCode`
- [ ] **Test** that translations appear instantly

---

## 🔧 Common Use Cases

### **1. Display Text Based on Current Language**

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return Text(l10n.departmentSettings);
  // Automatically updates when language changes
}
```

### **2. Conditional Layouts (RTL for Arabic)**

```dart
@override
Widget build(BuildContext context) {
  final direction = context.read<LanguageProvider>().textDirection;
  final isArabic = context.read<LanguageProvider>().isArabic;

  return Directionality(
    textDirection: direction,
    child: Row(
      textDirection: direction,
      children: [
        if (isArabic) RightSideWidget(),
        if (!isArabic) LeftSideWidget(),
      ],
    ),
  );
}
```

### **3. Language Selector Button (Only in Settings)**

```dart
// Only in DepartmentSettingsPage or similar
_langButton(
  label: 'EN',
  isSelected: context.read<LanguageProvider>().languageCode == 'en',
  onTap: () {
    context.read<LanguageProvider>().setEnglish();
  },
),
```

### **4. Watch Language Changes in Stateless Widget**

```dart
@override
Widget build(BuildContext context) {
  // Watch changes
  final lang = context.watch<LanguageProvider>();

  return Text(
    'Current language: ${lang.currentLanguageName}',
    // Rebuilds when language changes
  );
}
```

### **5. Get Language Code for Firestore**

```dart
Future<void> _saveProfile() async {
  final currentLang = context.read<LanguageProvider>().languageCode;

  await firestore.collection('user_profiles').doc(uid).set({
    'language': currentLang,  // Save for reference
    'name': name,
  });
  // NO NEED to call languageService.saveLanguage() again!
  // LanguageProvider already persisted it internally
}
```

---

## 🎯 Architecture Pattern for All Screens

**Every screen follows this pattern:**

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Get localized strings
    final l10n = AppLocalizations.of(context);

    // 2. Get language provider (only if you need language-specific logic)
    final lang = context.watch<LanguageProvider>();  // Use watch if rebuilding on change
    // OR
    final langCode = context.read<LanguageProvider>().languageCode;  // Use read if just checking

    // 3. Build UI with l10n strings
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myScreenTitle),  // Auto-translated
      ),
      body: Column(
        children: [
          if (lang.isArabic)
            Text(l10n.arabicSpecificText),
          Text(l10n.commonText),
        ],
      ),
    );
  }
}
```

---

## 🚨 DEBUGGING TIPS

### **Issue: Language not changing**

```dart
// Check 1: Is LanguageProvider in MultiProvider?
// ✅ Should be in main.dart MyApp class

// Check 2: Is screen watching Provider?
final lang = context.watch<LanguageProvider>();  // watch, not read
// ✅ Must use watch to trigger rebuild

// Check 3: Are you using AppLocalizations?
final l10n = AppLocalizations.of(context);
Text(l10n.someString);  // ✅ Correct
// Text('hardcoded string');  // ❌ Won't change
```

### **Issue: Language resets on screen open**

```dart
// ❌ Don't do this in initState
@override
void initState() {
  super.initState();
  context.read<LanguageProvider>().setLanguage('en');  // ❌ WRONG
}

// ✅ Just read it if needed
@override
void initState() {
  super.initState();
  final currentLang = context.read<LanguageProvider>().languageCode;
  // Use it, don't set it
}
```

### **Issue: Language not persisting**

```dart
// ❌ Don't manually save
context.read<LanguageProvider>().setEnglish();
await languageService.saveLanguage('en');  // ❌ WRONG, already saved

// ✅ LanguageProvider saves automatically
context.read<LanguageProvider>().setEnglish();  // ✅ Saves internally
```

---

## 📱 Role-Specific Screens (Department/Teacher/Student)

All three roles use the same LanguageProvider:

```dart
// DepartmentSettingsPage
context.read<LanguageProvider>().setEnglish();

// TeacherSettingsPage (if exists)
context.read<LanguageProvider>().setFrench();

// StudentSettingsPage (if exists)
context.read<LanguageProvider>().setArabic();

// All update globally, all persist, all roles see changes
```

---

## ✅ FINAL VALIDATION

After implementing this in all screens:

- [ ] Changing language in Settings updates all other screens instantly
- [ ] Language persists after app restart
- [ ] No logout when changing language
- [ ] RTL layout works for Arabic
- [ ] All screens show correct translated text
- [ ] No languageService imports in any file except language_service.dart itself
- [ ] No manual setLanguage() calls outside of language switch UI

**You're done! 🎉**
