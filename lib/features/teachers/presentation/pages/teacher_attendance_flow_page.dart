import 'package:flutter/material.dart';
import 'package:test/features/teachers/presentation/pages/teacher_subject_selection_page.dart';

// ========================================
// Teacher Attendance Flow Page
// Entry point for the multi-step attendance
// workflow used by teacher accounts.
// ========================================

/// Entry point for the teacher attendance flow.
/// Initiates the subject selection step.
class TeacherAttendanceFlowPage extends StatelessWidget {
  const TeacherAttendanceFlowPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
  });

  static const routeName = '/features/teachers/attendance/flow';

  final String teacherId;
  final String teacherEmail;

  @override
  Widget build(BuildContext context) {
    return TeacherSubjectSelectionPage(
      teacherId: teacherId,
      teacherEmail: teacherEmail,
    );
  }
}
