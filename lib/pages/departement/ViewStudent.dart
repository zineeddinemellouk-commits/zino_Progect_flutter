import 'package:flutter/material.dart';
import '../department_dashboard.dart';

class ViewStudent extends StatefulWidget {
  const ViewStudent({super.key});

  @override
  State<ViewStudent> createState() => _ViewStudentState();
}

class _ViewStudentState extends State<ViewStudent> {
  // Sample student data - in real app this would come from database
  final List<Map<String, dynamic>> students = [
    {
      "id": 1,
      "name": "Alice Johnson",
      "email": "alice.johnson@university.edu",
      "level": "L2",
      "classGroup": "Group 3",
      "phone": "+213 555 0123",
      "enrollmentDate": "2022-09-01",
      "attendanceRate": 94.2,
      "totalAbsences": 5,
      "justifiedAbsences": 2,
      "unjustifiedAbsences": 3,
      "status": "Active",
    },
    {
      "id": 2,
      "name": "Bob Smith",
      "email": "bob.smith@university.edu",
      "level": "M1",
      "classGroup": "Group 1",
      "phone": "+213 555 0456",
      "enrollmentDate": "2021-09-01",
      "attendanceRate": 87.5,
      "totalAbsences": 12,
      "justifiedAbsences": 8,
      "unjustifiedAbsences": 4,
      "status": "Active",
    },
    {
      "id": 3,
      "name": "Charlie Brown",
      "email": "charlie.brown@university.edu",
      "level": "L3",
      "classGroup": "Group 2",
      "phone": "+213 555 0789",
      "enrollmentDate": "2023-09-01",
      "attendanceRate": 91.8,
      "totalAbsences": 8,
      "justifiedAbsences": 5,
      "unjustifiedAbsences": 3,
      "status": "Active",
    },
    {
      "id": 4,
      "name": "Diana Wilson",
      "email": "diana.wilson@university.edu",
      "level": "L1",
      "classGroup": "Group 4",
      "phone": "+213 555 0321",
      "enrollmentDate": "2023-09-01",
      "attendanceRate": 96.7,
      "totalAbsences": 3,
      "justifiedAbsences": 1,
      "unjustifiedAbsences": 2,
      "status": "Active",
    },
  ];

  void _viewStudentDetails(int index) {
    final student = students[index];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StudentDetailsDialog(student: student);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: PreferredSize(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Academic Curator",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
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
      ),
      drawer: Drawer(
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
              _drawerItem(Icons.home, "Home", () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DepartmentDashboard()),
                );
              }),
              _drawerItem(Icons.person_add, "Add Student", () {
                Navigator.pop(context);
                // Navigate to AddStudent
              }),
              _drawerItem(Icons.school, "Add Teacher", () {
                Navigator.pop(context);
                // Navigate to AddTeacher
              }),
              _drawerItem(Icons.subject, "Add Subject", () {
                Navigator.pop(context);
                // Navigate to AddSubject
              }),
              _drawerItem(Icons.people, "View Students", () {
                Navigator.pop(context);
              }),
              _drawerItem(Icons.visibility, "View Justification", () {
                Navigator.pop(context);
                // Navigate to VewJustification
              }),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle background logo
          Positioned(
            top: 100,
            right: -50,
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/PixVerse_Image_Effect_prompt_invsibel backgrou.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Students Overview",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${students.length} students enrolled",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _viewStudentDetails(index),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        student["name"].split(" ").map((e) => e[0]).join(""),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student["name"],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${student["level"]} • ${student["classGroup"]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          student["email"],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: student["attendanceRate"] >= 90
                                              ? Colors.green.withOpacity(0.1)
                                              : student["attendanceRate"] >= 80
                                                  ? Colors.orange.withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "${student["attendanceRate"]}%",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: student["attendanceRate"] >= 90
                                                ? Colors.green
                                                : student["attendanceRate"] >= 80
                                                    ? Colors.orange
                                                    : Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
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
          currentIndex: 1, // Students tab
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Students",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: "Requests",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings",
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DepartmentDashboard()),
                );
                break;
              case 1:
                // Already on students page
                break;
              case 2:
                // Navigate to requests/justifications
                break;
              case 3:
                // Navigate to settings
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563EB)),
        title: Text(
          title,
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
}

class StudentDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailsDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      student["name"].split(" ").map((e) => e[0]).join(""),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student["name"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF004AC6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${student["level"]} • ${student["classGroup"]}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF004AC6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow("Email", student["email"]),
            _detailRow("Phone", student["phone"]),
            _detailRow("Enrollment Date", student["enrollmentDate"]),
            _detailRow("Status", student["status"]),
            const SizedBox(height: 16),
            const Text(
              "Attendance Summary",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _attendanceCard(
                    "Attendance Rate",
                    "${student["attendanceRate"]}%",
                    student["attendanceRate"] >= 90 ? Colors.green : student["attendanceRate"] >= 80 ? Colors.orange : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _attendanceCard(
                    "Total Absences",
                    student["totalAbsences"].toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _attendanceCard(
                    "Justified",
                    student["justifiedAbsences"].toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _attendanceCard(
                    "Unjustified",
                    student["unjustifiedAbsences"].toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}