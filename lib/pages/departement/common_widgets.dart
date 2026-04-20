import 'package:flutter/material.dart';
import 'package:test/pages/department_dashboard.dart';
import 'package:test/main.dart'; // ✅ added
import 'AddStudent.dart';
import 'AddTeacher.dart';
import 'AddSubject.dart';
import 'VewJustification.dart';
import 'ViewStudent.dart';
import 'ViewTeachers.dart';
import 'ViewSubjects.dart';
// ✅ removed: import 'package:test/pages/login_page.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/pages/department_settings_page.dart';
import 'package:test/helpers/localization_helper.dart';

Future<void> _logoutFromDepartment(BuildContext context) async {
  try {
    await DepartmentAuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HodooriLoginScreen()), // ✅ fixed
      (_) => false,
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
  }
}

PreferredSizeWidget departmentAppBar(BuildContext context, String title) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(70),
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _logoutFromDepartment(context),
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
    ),
  );
}

Drawer departmentDrawer(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Drawer(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8F9FB), const Color(0xFFE8F0FE)],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerItem(context, Icons.home, context.tr('dashboard'), () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DepartmentDashboard(),
              ),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.person_add, context.tr('add'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddStudent()),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.school, context.tr('teachers'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeacher()),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.subject, context.tr('subjects'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSubject()),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.people, context.tr('students'), () {
            Navigator.pop(context);
            Navigator.pushNamed(context, ViewStudent.routeName);
          }, isDarkMode),
          _drawerItem(context, Icons.badge, context.tr('teachers'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewTeachers()),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.book, context.tr('subjects'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewSubjects()),
            );
          }, isDarkMode),
          _drawerItem(context, Icons.visibility, context.tr('attendance'), () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VewJustification()),
            );
          }, isDarkMode),
          const Divider(height: 20),
          _drawerItem(context, Icons.logout, context.tr('cancel'), () {
            Navigator.pop(context);
            _logoutFromDepartment(context);
          }, isDarkMode),
        ],
      ),
    ),
  );
}

Widget _drawerItem(
  BuildContext context,
  IconData icon,
  String text,
  VoidCallback onTap,
  bool isDarkMode,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

Widget departmentBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF004AC6), Color(0xFF2563EB)]),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard),
          label: context.tr('dashboard'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.school),
          label: context.tr('classes'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment),
          label: context.tr('attendance'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: context.tr('settings'),
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DepartmentDashboard(),
              ),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewStudent()),
            );
            break;
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VewJustification()),
            );
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DepartmentSettingsPage(),
              ),
            );
            break;
        }
      },
    ),
  );
}
