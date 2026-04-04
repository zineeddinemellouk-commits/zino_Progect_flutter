import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'departement/AddStudent.dart';
import 'package:test/pages/departement/AddSubject.dart';
import 'package:test/pages/departement/AddTeacher.dart';

class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard({super.key});

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  final String universityName = "belhadj bouchayeb National University";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentManagementProvider>().initializeBaseData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentManagementProvider>();
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
            StreamBuilder(
              stream: provider.watchAllStudents(),
              builder: (context, studentsSnapshot) {
                final students = studentsSnapshot.data ?? const [];
                final totalStudents = students.length;
                final totalPresent = students.fold<int>(
                  0,
                  (sum, s) => sum + s.attendancePercentage,
                );
                final attendance = totalStudents == 0
                    ? 0.0
                    : (totalPresent / totalStudents).clamp(0, 100).toDouble();

                return StreamBuilder(
                  stream: provider.watchTeachers(),
                  builder: (context, teachersSnapshot) {
                    final teachers = teachersSnapshot.data ?? const [];
                    return Row(
                      children: [
                        Expanded(
                          child: _statCard("Students", totalStudents.toString()),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard("Teachers", teachers.length.toString()),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            "Attendance",
                            "${attendance.toStringAsFixed(1)}%",
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Weekly Trends",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: provider.watchAllStudents(),
              builder: (context, snapshot) {
                final students = snapshot.data ?? const [];
                final attendance = students.isEmpty
                    ? 0.0
                    : students
                            .fold<int>(0, (sum, s) => sum + s.attendancePercentage) /
                        students.length;
                final trend = [
                  (attendance * 0.6).clamp(0, 100),
                  (attendance * 0.75).clamp(0, 100),
                  (attendance * 0.9).clamp(0, 100),
                  attendance.clamp(0, 100),
                  (attendance * 1.05).clamp(0, 100),
                ];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: trend.map((e) => _bar(e.toDouble())).toList(),
                );
              },
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
