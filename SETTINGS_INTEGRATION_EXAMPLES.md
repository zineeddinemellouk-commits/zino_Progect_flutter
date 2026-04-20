# 🔗 Settings Integration Examples

## How to Add Settings Button to Student/Teacher Pages

---

## ✅ Example 1: Simple AppBar with Settings Icon

### For Student Pages:

```dart
import 'package:test/features/students/presentation/pages/student_settings_page.dart';
import 'package:test/helpers/localization_helper.dart';

AppBar(
  title: Text(context.tr('dashboard')),
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.settings, color: Colors.white),
      onPressed: () {
        Navigator.pushNamed(context, StudentSettingsPage.routeName);
      },
      tooltip: context.tr('settings'),
    ),
  ],
)
```

### For Teacher Pages:

```dart
import 'package:test/features/teachers/presentation/pages/teacher_settings_page.dart';
import 'package:test/helpers/localization_helper.dart';

AppBar(
  title: Text(context.tr('dashboard')),
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.settings, color: Colors.white),
      onPressed: () {
        Navigator.pushNamed(context, TeacherSettingsPage.routeName);
      },
      tooltip: context.tr('settings'),
    ),
  ],
)
```

---

## ✅ Example 2: Settings in Drawer Menu

### For Student Drawer:

```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
          ),
        ),
        child: Text(context.tr('student'), style: TextStyle(color: Colors.white)),
      ),
      ListTile(
        leading: Icon(Icons.home),
        title: Text(context.tr('dashboard')),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.settings),
        title: Text(context.tr('settings')),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, StudentSettingsPage.routeName);
        },
      ),
    ],
  ),
)
```

### For Teacher Drawer:

```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
          ),
        ),
        child: Text(context.tr('teacher'), style: TextStyle(color: Colors.white)),
      ),
      ListTile(
        leading: Icon(Icons.home),
        title: Text(context.tr('dashboard')),
        onTap: () => Navigator.pop(context),
      ),
      ListTile(
        leading: Icon(Icons.settings),
        title: Text(context.tr('settings')),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, TeacherSettingsPage.routeName);
        },
      ),
    ],
  ),
)
```

---

## ✅ Example 3: Bottom Navigation with Settings Tab

### For Student Dashboard:

```dart
class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: context.tr('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: context.tr('profile'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: context.tr('settings'),
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            // Navigate to Settings
            Navigator.pushNamed(context, StudentSettingsPage.routeName);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const StudentHomeView();
      case 1:
        return const StudentProfileView();
      default:
        return const SizedBox();
    }
  }
}
```

### For Teacher Dashboard:

```dart
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard')),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: context.tr('dashboard'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: context.tr('profile'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: context.tr('settings'),
          ),
        ],
        onTap: (index) {
          if (index == 2) {
            // Navigate to Settings
            Navigator.pushNamed(context, TeacherSettingsPage.routeName);
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const TeacherHomeView();
      case 1:
        return const TeacherProfileView();
      default:
        return const SizedBox();
    }
  }
}
```

---

## ✅ Example 4: Floating Action Button for Settings

### For Student Profile:

```dart
Scaffold(
  appBar: AppBar(title: Text(context.tr('profile'))),
  body: ProfileContent(),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.pushNamed(context, StudentSettingsPage.routeName);
    },
    tooltip: context.tr('settings'),
    child: Icon(Icons.settings),
  ),
)
```

### For Teacher Profile:

```dart
Scaffold(
  appBar: AppBar(title: Text(context.tr('profile'))),
  body: ProfileContent(),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.pushNamed(context, TeacherSettingsPage.routeName);
    },
    tooltip: context.tr('settings'),
    child: Icon(Icons.settings),
  ),
)
```

---

## ✅ Example 5: Profile Card with Settings Button

### For Student Profile Card:

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${studentName}',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'student@university.edu',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, StudentSettingsPage.routeName);
        },
        icon: Icon(Icons.settings),
        label: Text(context.tr('settings')),
      ),
    ],
  ),
)
```

### For Teacher Profile Card:

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${teacherName}',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'teacher@university.edu',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, TeacherSettingsPage.routeName);
        },
        icon: Icon(Icons.settings),
        label: Text(context.tr('settings')),
      ),
    ],
  ),
)
```

---

## ✅ Example 6: Complete Navigation Helper

Create a reusable helper file for navigation:

**File: `lib/helpers/settings_navigation.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:test/features/students/presentation/pages/student_settings_page.dart';
import 'package:test/features/teachers/presentation/pages/teacher_settings_page.dart';

class SettingsNavigation {
  /// Navigate to Student Settings
  static void toStudentSettings(BuildContext context) {
    Navigator.pushNamed(context, StudentSettingsPage.routeName);
  }

  /// Navigate to Teacher Settings
  static void toTeacherSettings(BuildContext context) {
    Navigator.pushNamed(context, TeacherSettingsPage.routeName);
  }

  /// Get Student Settings Route
  static String get studentSettingsRoute => StudentSettingsPage.routeName;

  /// Get Teacher Settings Route
  static String get teacherSettingsRoute => TeacherSettingsPage.routeName;
}
```

**Usage:**

```dart
ElevatedButton(
  onPressed: () => SettingsNavigation.toStudentSettings(context),
  child: Text('Go to Settings'),
),
```

---

## ✅ Example 7: Pop-up Menu with Settings

### For Student Actions Menu:

```dart
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'settings') {
      Navigator.pushNamed(context, StudentSettingsPage.routeName);
    }
  },
  itemBuilder: (BuildContext context) => [
    PopupMenuItem(
      value: 'settings',
      child: Row(
        children: [
          Icon(Icons.settings, color: Colors.black),
          SizedBox(width: 10),
          Text(context.tr('settings')),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'help',
      child: Row(
        children: [
          Icon(Icons.help, color: Colors.black),
          SizedBox(width: 10),
          Text('Help'),
        ],
      ),
    ),
  ],
  child: Icon(Icons.more_vert),
)
```

### For Teacher Actions Menu:

```dart
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'settings') {
      Navigator.pushNamed(context, TeacherSettingsPage.routeName);
    }
  },
  itemBuilder: (BuildContext context) => [
    PopupMenuItem(
      value: 'settings',
      child: Row(
        children: [
          Icon(Icons.settings, color: Colors.black),
          SizedBox(width: 10),
          Text(context.tr('settings')),
        ],
      ),
    ),
    PopupMenuItem(
      value: 'help',
      child: Row(
        children: [
          Icon(Icons.help, color: Colors.black),
          SizedBox(width: 10),
          Text('Help'),
        ],
      ),
    ),
  ],
  child: Icon(Icons.more_vert),
)
```

---

## 🎯 Quick Copy-Paste: Recommended Integration

**For most apps, I recommend this simple integration:**

### In Student Page AppBar:

```dart
AppBar(
  title: Text('Dashboard'),
  actions: [
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, StudentSettingsPage.routeName),
    ),
  ],
)
```

### In Teacher Page AppBar:

```dart
AppBar(
  title: Text('Dashboard'),
  actions: [
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Navigator.pushNamed(context, TeacherSettingsPage.routeName),
    ),
  ],
)
```

---

## 📝 Import Requirements

Add these imports to your page:

```dart
import 'package:test/features/students/presentation/pages/student_settings_page.dart';
import 'package:test/features/teachers/presentation/pages/teacher_settings_page.dart';
import 'package:test/helpers/localization_helper.dart'; // For context.tr()
```

---

## ✅ Localization Keys Reference

All keys are already translated. Common ones for integration:

| Key                | English          | Français             | العربية        |
| ------------------ | ---------------- | -------------------- | -------------- |
| `settings`         | Settings         | Paramètres           | الإعدادات      |
| `dashboard`        | Dashboard        | Tableau de bord      | لوحة التحكم    |
| `profile`          | Profile          | Profil               | الملف الشخصي   |
| `account_settings` | Account Settings | Paramètres du compte | إعدادات الحساب |
| `language`         | Language         | Langue               | اللغة          |

---

## 🚀 That's It!

Pick any of the integration examples above and you're done. The Settings pages are fully functional and ready to use with just one line of navigation code!
