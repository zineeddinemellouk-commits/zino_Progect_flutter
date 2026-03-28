import 'package:flutter/material.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'departement/AddStudent.dart';
import 'package:test/pages/departement/AddSubject.dart';
import 'package:test/pages/departement/AddTeacher.dart';

class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard({super.key});

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  // TODO: replace these with real values from your database when available
  final String universityName = "belhadj bouchayeb National University";

  final List<Map<String, dynamic>> students = [
    {
      "id": 1,
      "name": "Alice",
      "attendedDays": 28,
      "weeklyAttendance": [5, 6, 5, 6, 6],
    },
    {
      "id": 2,
      "name": "Bob",
      "attendedDays": 27,
      "weeklyAttendance": [5, 5, 6, 6, 5],
    },
    {
      "id": 3,
      "name": "Charlie",
      "attendedDays": 26,
      "weeklyAttendance": [5, 5, 5, 6, 5],
    },
  ];

  final List<Map<String, dynamic>> teachers = [
    {"id": 1, "name": "Dr. Smith"},
    {"id": 2, "name": "Prof. Ahmed"},
  ];

  final int totalClassDays = 30;
  final int classesPerWeek = 6;

  int get totalStudents => students.length;
  int get totalTeachers => teachers.length;

  int get totalPresentDays => students.fold(
    0,
    (sum, student) => sum + (student["attendedDays"] as int),
  );

  int get totalPossibleDays => totalClassDays * totalStudents;

  double get attendancePercent {
    if (totalPossibleDays <= 0) return 0;
    final percent = (totalPresentDays / totalPossibleDays) * 100;
    return percent.clamp(0, 100);
  }

  List<double> get weeklyTrendPercent {
    const weekCount = 5;
    return List.generate(weekCount, (weekIndex) {
      final totalWeekPresence = students.fold<int>(
        0,
        (sum, student) =>
            sum + (student["weeklyAttendance"] as List<int>)[weekIndex],
      );

      final totalPossibleWeek = totalStudents * classesPerWeek;
      if (totalPossibleWeek <= 0) return 0;

      return (totalWeekPresence / totalPossibleWeek) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, "Academic Curator - $universityName"),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Systems Overview",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    universityName,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Generate Report"),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "View Audit Log",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statCard("Students", totalStudents.toString()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard("Teachers", totalTeachers.toString()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    "Attendance",
                    "${attendancePercent.toStringAsFixed(1)}%",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Weekly Trends",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weeklyTrendPercent.map((e) => _bar(e)).toList(),
            ),
            const SizedBox(height: 30),
            // Quick Actions Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Add Student
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddStudent(),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text("Add Student"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Add Teacher
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddTeacher(),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.school),
                          label: const Text("Add Teacher"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Add Subject
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AddSubject(),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.subject),
                          label: const Text("Add Subject"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Generate Report action
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Generating Report..."),
                              ),
                            );
                          },
                          icon: const Icon(Icons.description),
                          label: const Text("Generate Report"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Classes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 20,
      height: 100,
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
