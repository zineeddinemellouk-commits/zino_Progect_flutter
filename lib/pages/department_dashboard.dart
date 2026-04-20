import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/helpers/localization_helper.dart';
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
      appBar: departmentAppBar(context, context.tr('dashboard')),
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
                crossAxisAlignment: context.isRtl
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('dashboard'),
                    style: const TextStyle(
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
                        child: Text(context.tr('report')),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          context.tr('filter'),
                          style: const TextStyle(color: Colors.white),
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
                          child: _statCard(
                            context.tr('students'),
                            totalStudents.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            context.tr('teachers'),
                            teachers.length.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            context.tr('attendance'),
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
            Text(
              context.tr('attendance'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: provider.watchAllStudents(),
              builder: (context, snapshot) {
                final students = snapshot.data ?? const [];
                final attendance = students.isEmpty
                    ? 0.0
                    : students.fold<int>(
                            0,
                            (sum, s) => sum + s.attendancePercentage,
                          ) /
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddStudent(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('students')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddTeacher(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('teachers')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddSubject(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('subjects')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: departmentBottomNav(context, 0),
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8),
        ),
        height: (value * 1.5).clamp(20, 200).toDouble(),
      ),
    );
  }
}
