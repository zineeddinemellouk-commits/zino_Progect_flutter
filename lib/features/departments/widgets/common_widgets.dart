import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/dashboard/screens/department_dashboard.dart';
import 'package:test/features/students/screens/add_student_screen.dart';
import 'package:test/features/teachers/screens/add_teacher_screen.dart';
import 'package:test/features/subjects/screens/add_subject_screen.dart';
import 'package:test/features/attendance/screens/view_justification_screen.dart';
import 'package:test/features/attendance/screens/view_exclude_screen.dart';
import 'package:test/features/attendance/screens/department_attendance_history_screen.dart';
import 'package:test/features/students/screens/view_students_screen.dart';
import 'package:test/features/teachers/screens/view_teachers_screen.dart';
import 'package:test/features/subjects/screens/view_subjects_screen.dart';
import 'package:test/features/departments/screens/create_admin_screen.dart';
import 'package:test/features/departments/screens/department_settings_screen.dart';
import 'package:test/core/helpers/localization_helper.dart';
import 'package:test/core/theme/app_theme.dart';
import 'package:test/services/auth_service.dart';

// FIXED: Added feature-specific color constants for menu item differentiation
const Color _featureColorTeacher = Color(0xFF7C3AED); // Purple for teachers
const Color _featureColorSubject = Color(0xFF059669); // Green for subjects
const Color _featureColorExclude = Color(0xFFB54708); // Orange for exclusions
const Color _featureColorAdmin = Color(0xFF6366F1); // Indigo for admin

Future<void> _logoutFromDepartment(BuildContext context) async {
  await AuthService.logout(context);
}

PreferredSizeWidget departmentAppBar(
  BuildContext context,
  String title, {
  bool showBackButton = false,
  Widget? customLeading,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(70),
    child: Container(
      decoration: BoxDecoration(
        // FIXED: Replaced hardcoded gradient colors with theme colors
        gradient: const LinearGradient(
          colors: [AppTheme.lightPrimaryDark, AppTheme.lightPrimary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/l10n/images/logo_hodori.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading:
            customLeading ??
            (showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )),
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
            // FIXED: Replaced hardcoded gradient with theme colors
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.lightPrimary, AppTheme.lightPrimaryDark],
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
            // FIXED: Replaced hardcoded color with theme primary
            AppTheme.lightPrimary,
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
            // FIXED: Replaced hardcoded color with theme primary
            AppTheme.lightPrimary,
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
          // NEW: Added Attendance History button grouped by subject/teacher
          _drawerIconItem(
            context,
            Icons.history_rounded,
            'Attendance History',
            const Color(0xFF06B6D4),
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DepartmentAttendanceHistoryScreen(),
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
            // FIXED: Replaced hardcoded color with theme primary
            AppTheme.lightPrimary,
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
            // FIXED: Using feature color for teacher-related items
            _featureColorTeacher,
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
            // FIXED: Using feature color for subject-related items
            _featureColorSubject,
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
            // FIXED: Replaced hardcoded color with theme primary
            AppTheme.lightPrimary,
            () {
              Navigator.pop(context);
              Navigator.pushNamed(context, ViewStudent.routeName);
            },
          ),
          _drawerIconItem(
            context,
            Icons.manage_accounts_outlined,
            'View Teachers',
            // FIXED: Using feature color for teacher-related items
            _featureColorTeacher,
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
            // FIXED: Using feature color for subject-related items
            _featureColorSubject,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewSubjects()),
              );
            },
          ),
          _drawerIconItem(
            context,
            Icons.gpp_maybe_outlined,
            'View Exclude',
            // FIXED: Using feature color for exclusion-related items
            _featureColorExclude,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViewExclude()),
              );
            },
          ),

          // ── Admin Section ────────────────────────────────────────────
          _sectionLabel(context, 'Administration'),
          _drawerIconItem(
            context,
            Icons.admin_panel_settings_outlined,
            'Create Admin',
            // FIXED: Using feature color for admin-related items
            _featureColorAdmin,
            () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
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
            // FIXED: Replaced hardcoded color with theme error color
            AppTheme.lightError,
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
      // FIXED: Replaced hardcoded hover color with theme primary color
      hoverColor: AppTheme.lightPrimary.withOpacity(0.08),
    ),
  );
}

Widget departmentBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: BoxDecoration(
      // FIXED: Replaced hardcoded gradient colors with theme colors
      gradient: const LinearGradient(
        colors: [AppTheme.lightPrimaryDark, AppTheme.lightPrimary],
      ),
      boxShadow: const [
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
