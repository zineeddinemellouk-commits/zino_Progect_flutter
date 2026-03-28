import 'package:flutter/material.dart';
import 'package:test/pages/department_dashboard.dart';
import 'AddStudent.dart';
import 'AddTeacher.dart';
import 'AddSubject.dart';
import 'VewJustification.dart';
import 'ViewStudent.dart';

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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
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
  return Drawer(
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F9FB), Color(0xFFE8F0FE)],
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  'Academic Curator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Department Portal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _drawerItem(context, Icons.home, "Home", () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DepartmentDashboard()),
            );
          }),
          _drawerItem(context, Icons.person_add, "Add Student", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddStudent()),
            );
          }),
          _drawerItem(context, Icons.school, "Add Teacher", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTeacher()),
            );
          }),
          _drawerItem(context, Icons.subject, "Add Subject", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSubject()),
            );
          }),
          _drawerItem(context, Icons.people, "View Students", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ViewStudent()),
            );
          }),
          _drawerItem(context, Icons.visibility, "View Justification", () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VewJustification()),
            );
          }),
        ],
      ),
    ),
  );
}

Widget _drawerItem(BuildContext context, IconData icon, String text, VoidCallback onTap) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}

Widget departmentBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, -2),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: "Classes"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Requests"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const DepartmentDashboard()));
            break;
          case 1:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ViewStudent()));
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const VewJustification()));
            break;
          case 3:
            // settings stub
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings not implemented yet')),
            );
            break;
        }
      },
    ),
  );
}
