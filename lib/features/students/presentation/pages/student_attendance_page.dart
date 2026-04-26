import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/student_feature_model.dart';

class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final StudentsFirestoreService _service = StudentsFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final studentId = currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (studentId.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? Colors.grey[850] : Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'My Attendance',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Unable to load attendance - No user logged in',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Attendance',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<StudentFeatureModel>>(
        stream: _service.watchStudentById(studentId),
        builder: (context, studentSnapshot) {
          final student = studentSnapshot.data?.isNotEmpty == true
              ? studentSnapshot.data!.first
              : null;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('attendance')
                .where('studentId', isEqualTo: studentId)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting ||
                  attendanceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (student == null) {
                return Center(
                  child: Text(
                    'No student data available',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }

              final attendancePercent = ((student.attendanceRate) * 100).clamp(
                0,
                100,
              );
              final attendanceText = attendancePercent.toStringAsFixed(1);
              final attendanceRecords = attendanceSnapshot.data?.docs ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Card: Blue Gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1e40af)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'My Attendance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$attendanceText%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Attendance Sessions List
                    if (attendanceRecords.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'No attendance records yet',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attendanceRecords.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final record = attendanceRecords[index].data();
                          return _AttendanceSessionCard(
                            record: record,
                            isDark: isDark,
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Individual Attendance Session Card
class _AttendanceSessionCard extends StatelessWidget {
  const _AttendanceSessionCard({required this.record, required this.isDark});

  final Map<String, dynamic> record;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final date = (record['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final subject = (record['subject'] ?? 'Unknown Subject').toString();
    final group = (record['group'] ?? 'N/A').toString();
    final status = (record['status'] ?? 'absent').toString().toLowerCase();
    final isPresent = status == 'present';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            _formatDate(date),
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Subject and Group Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPresent
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPresent ? 'Present' : 'Absent',
                  style: TextStyle(
                    color: isPresent
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
