import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

PreferredSizeWidget departmentAppBar(
  BuildContext context,
  String title, {
  bool showBackButton = false,
}) {
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
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : Builder(
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
  final user = FirebaseAuth.instance.currentUser;
  final userEmail = user?.email ?? '';

  return Drawer(
    child: Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hodoori',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Smart Attendance',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  userEmail,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Navigation Section ──────────────────────────────────────
          _sectionLabel(context, 'Navigation'),
          _drawerIconItem(
            context,
            Icons.dashboard_outlined,
            'Dashboard',
            const Color(0xFF2563EB),
            () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DepartmentDashboard(),
                ),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.fact_check_outlined,
            'Attendance',
            const Color(0xFF2563EB),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VewJustification(),
                ),
              );
            },
          ),

          // ── Add New Section ─────────────────────────────────────────
          _sectionLabel(context, 'Add New'),
          _drawerIconItem(
            context,
            Icons.person_add_outlined,
            'Add Student',
            const Color(0xFF2563EB),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStudent()),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.school_outlined,
            'Add Teacher',
            const Color(0xFF7C3AED),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTeacher()),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.menu_book_outlined,
            'Add Subject',
            const Color(0xFF059669),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddSubject()),
              );
            },
          ),

          // ── Manage Section ──────────────────────────────────────────
          _sectionLabel(context, 'Manage'),
          _drawerIconItem(
            context,
            Icons.people_outline,
            'View Students',
            const Color(0xFF2563EB),
            () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ViewStudent.routeName);
            },
          ),
          _drawerIconItem(
            context,
            Icons.manage_accounts_outlined,
            'View Teachers',
            const Color(0xFF7C3AED),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewTeachers()),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.library_books_outlined,
            'View Subjects',
            const Color(0xFF059669),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewSubjects()),
              );
            },
          ),

          // ── Bottom Items ────────────────────────────────────────────
          const Divider(height: 20, thickness: 1),
          _drawerIconItem(
            context,
            Icons.settings_outlined,
            'Settings',
            Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DepartmentSettingsPage(),
                ),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.logout,
            'Sign Out',
            const Color(0xFFDC2626),
            () {
              Navigator.pop(context);
              _logoutFromDepartment(context);
            },
          ),
        ],
      ),
    ),
  );
}

Widget _sectionLabel(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    ),
  );
}

Widget _drawerIconItem(
  BuildContext context,
  IconData icon,
  String text,
  Color color,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Icon(icon, color: color, size: 20)),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
      hoverColor: const Color(0xFF2563EB).withOpacity(0.08),
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
