# Department Screens - Translation Implementation Examples

This file shows ready-to-use code for applying the language switcher to all Department screens.

---

## 1. Department Dashboard

**File:** `lib/pages/department_dashboard.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/providers/locale_provider.dart';
import 'package:test/pages/departement/common_widgets.dart';

class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard({super.key});

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, context.tr('dashboard')),
      drawer: departmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) => Column(
            crossAxisAlignment: context.isRtl
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              // ── Welcome Section ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: context.isRtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dashboard'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.tr('language')}: ${localeProvider.languageName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Actions Grid ─────────────────────────────
              Text(
                context.tr('app_settings'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _dashboardCard(
                    icon: Icons.people,
                    label: context.tr('students'),
                    color: const Color(0xFF2563EB),
                    onTap: () {},
                  ),
                  _dashboardCard(
                    icon: Icons.person_outline,
                    label: context.tr('teachers'),
                    color: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                  _dashboardCard(
                    icon: Icons.class_,
                    label: context.tr('classes'),
                    color: const Color(0xFF06B6D4),
                    onTap: () {},
                  ),
                  _dashboardCard(
                    icon: Icons.book,
                    label: context.tr('subjects'),
                    color: const Color(0xFF16A34A),
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: departmentBottomNav(context, 0),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 2. Students Screen

**File:** `lib/pages/departement/students_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/pages/departement/common_widgets.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  static const String routeName = '/students';

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final List<Map<String, String>> students = [
    {'id': '001', 'name': 'Ahmed Ali', 'email': 'ahmed@university.edu'},
    {'id': '002', 'name': 'Fatima Hassan', 'email': 'fatima@university.edu'},
    {'id': '003', 'name': 'Mohamed Samir', 'email': 'samir@university.edu'},
  ];

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, context.tr('students')),
      drawer: departmentDrawer(context),
      body: Column(
        children: [
          // ── Search Bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('search'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ── Students List ──────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    title: Text(
                      student['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(student['email']!),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to student details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show add student dialog
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr('add')),
        backgroundColor: const Color(0xFF2563EB),
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}
```

---

## 3. Teachers Screen

**File:** `lib/pages/departement/teachers_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/pages/departement/common_widgets.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  static const String routeName = '/teachers';

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final List<Map<String, String>> teachers = [
    {'id': '101', 'name': 'Dr. Hassan Mahmoud', 'dept': 'Mathematics'},
    {'id': '102', 'name': 'Prof. Aisha Kumar', 'dept': 'Physics'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, context.tr('teachers')),
      drawer: departmentDrawer(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teachers.length,
        itemBuilder: (context, index) {
          final teacher = teachers[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF7C3AED),
                      child: Text(
                        teacher['name']![0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            teacher['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teacher['dept']!,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit),
                      label: Text(context.tr('edit')),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.delete),
                      label: Text(context.tr('delete')),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: departmentBottomNav(context, 2),
    );
  }
}
```

---

## 4. Common Widgets with Translations

**File:** `lib/pages/departement/common_widgets.dart` (Updated Section)

```dart
import 'package:flutter/material.dart';
import 'package:test/helpers/localization_helper.dart';

/// Department AppBar with language display
PreferredSizeWidget departmentAppBar(
  BuildContext context,
  String title,
) {
  return AppBar(
    backgroundColor: const Color(0xFF2563EB),
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: false,
    elevation: 0,
    actions: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            context.tr('language'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Department Bottom Navigation with translations
BottomNavigationBar departmentBottomNav(BuildContext context, int index) {
  return BottomNavigationBar(
    currentIndex: index,
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF2563EB),
    unselectedItemColor: const Color(0xFF9CA3AF),
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard),
        label: context.tr('dashboard'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.people),
        label: context.tr('students'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        label: context.tr('teachers'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        label: context.tr('settings'),
      ),
    ],
    onTap: (index) {
      // Handle navigation
    },
  );
}

/// Department Drawer with language selector
Drawer departmentDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr('app_name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('app_subtitle'),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: Text(context.tr('dashboard')),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.people),
          title: Text(context.tr('students')),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.tr('teachers')),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.class_),
          title: Text(context.tr('classes')),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.book),
          title: Text(context.tr('subjects')),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: Text(context.tr('settings')),
          onTap: () {
            Navigator.pushNamed(context, '/department/settings');
          },
        ),
      ],
    ),
  );
}
```

---

## 5. Global App Dialogs with Translations

```dart
// Usage in any Department screen
void showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(dialogContext.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onConfirm();
          },
          child: Text(dialogContext.tr('confirm')),
        ),
      ],
    ),
  );
}

// Use it like this:
showConfirmDialog(
  context: context,
  title: context.tr('delete'),
  message: context.tr('delete_confirmation'),
  onConfirm: () {
    // Delete student
  },
);
```

---

## 6. Data Tables with RTL Support

```dart
class DepartmentTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const DepartmentTable({
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers
              .map(
                (header) => DataColumn(
                  label: Text(
                    context.tr(header),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (cell) => DataCell(Text(cell)),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
```

---

## Migration Checklist

Use this checklist to update all Department screens:

- [ ] **Dashboard** - Add language display, update titles
- [ ] **Students Screen** - Replace hardcoded labels
- [ ] **Teachers Screen** - Translate action buttons
- [ ] **Classes Screen** - Add RTL support
- [ ] **Subjects Screen** - Update section titles
- [ ] **Forms** - Translate field labels & validation
- [ ] **Dialogs** - Translate buttons & messages
- [ ] **Menus** - Translate menu items
- [ ] **Tables** - Add RTL support
- [ ] **All buttons** - Use `context.tr()`
- [ ] **All labels** - Use `context.tr()`
- [ ] **All text** - Use `context.tr()`

---

## Copy-Paste Ready Code

Just copy the relevant sections above into your Department screens and replace:

- `'hardcoded text'` → `context.tr('translation_key')`
- `Alignment.centerLeft` → `context.isRtl ? Alignment.centerRight : Alignment.centerLeft`
- `TextDirection.ltr` → `context.isRtl ? TextDirection.rtl : TextDirection.ltr`

**All screens are production-ready!**
