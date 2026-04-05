import 'package:flutter/material.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';

class TeacherGroupAttendancePage extends StatefulWidget {
  const TeacherGroupAttendancePage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
    required this.group,
  });

  final String teacherId;
  final String teacherEmail;
  final TeacherGroupOverview group;

  @override
  State<TeacherGroupAttendancePage> createState() =>
      _TeacherGroupAttendancePageState();
}

class _TeacherGroupAttendancePageState
    extends State<TeacherGroupAttendancePage> {
  final TeachersFirestoreService _service = TeachersFirestoreService();
  final Map<String, bool> _isPresentByStudentId = <String, bool>{};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.groupName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.group.levelName,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<StudentFeatureModel>>(
        stream: _service.watchTeacherGroupStudents(
          teacherId: widget.teacherId,
          teacherEmail: widget.teacherEmail,
          groupId: widget.group.groupId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load students: ${snapshot.error}'),
              ),
            );
          }

          final students = snapshot.data ?? const <StudentFeatureModel>[];
          for (final student in students) {
            _isPresentByStudentId.putIfAbsent(student.id, () => true);
          }

          if (students.isEmpty) {
            return const Center(
              child: Text(
                'No students in this group.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent = _isPresentByStudentId[student.id] ?? true;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFE8ECFF),
                            child: Text(
                              student.fullName.isEmpty
                                  ? '?'
                                  : student.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF4A40CF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    color: Color(0xFF101828),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.email,
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            selected: isPresent,
                            showCheckmark: false,
                            selectedColor: const Color(0xFFE7F8EF),
                            backgroundColor: const Color(0xFFF2F4F7),
                            side: BorderSide.none,
                            label: Text(
                              'Present',
                              style: TextStyle(
                                color: isPresent
                                    ? const Color(0xFF067647)
                                    : const Color(0xFF667085),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _isPresentByStudentId[student.id] = true;
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            selected: !isPresent,
                            showCheckmark: false,
                            selectedColor: const Color(0xFFFEE4E2),
                            backgroundColor: const Color(0xFFF2F4F7),
                            side: BorderSide.none,
                            label: Text(
                              'Absent',
                              style: TextStyle(
                                color: !isPresent
                                    ? const Color(0xFFB42318)
                                    : const Color(0xFF667085),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() {
                                _isPresentByStudentId[student.id] = false;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitAttendance(students),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A40CF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit Attendance'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitAttendance(List<StudentFeatureModel> students) async {
    setState(() => _isSubmitting = true);
    try {
      final payload = <String, bool>{
        for (final student in students)
          student.id: _isPresentByStudentId[student.id] ?? true,
      };

      await _service.submitGroupAttendance(
        teacherId: widget.teacherId,
        group: widget.group,
        isPresentByStudentId: payload,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted and saved to history.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
