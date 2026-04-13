import 'package:cloud_firestore/cloud_firestore.dart';

enum AbsenceStatus { pending, justified, rejected }

class AbsenceFeatureModel {
  const AbsenceFeatureModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subjectName,
    required this.courseCode,
    required this.courseName,
    required this.createdAt,
    required this.deadlineAt,
    required this.status,
    this.justificationId,
    this.submittedAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String subjectName;
  final String courseCode;
  final String courseName;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final AbsenceStatus status;
  final String? justificationId;
  final DateTime? submittedAt;

  bool get isExpired =>
      status == AbsenceStatus.rejected || DateTime.now().isAfter(deadlineAt);

  int get remainingMilliseconds {
    final remaining = deadlineAt.difference(DateTime.now());
    return remaining.inMilliseconds > 0 ? remaining.inMilliseconds : 0;
  }

  String get remainingTimeFormatted {
    if (status == AbsenceStatus.rejected || status == AbsenceStatus.justified) {
      return status == AbsenceStatus.justified ? 'SUBMITTED' : 'EXPIRED';
    }

    final remaining = remainingMilliseconds;
    if (remaining <= 0) return 'EXPIRED';

    final duration = Duration(milliseconds: remaining);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m remaining';
  }

  bool get isUrgent =>
      remainingMilliseconds < 86400000 &&
      status == AbsenceStatus.pending &&
      DateTime.now().isBefore(deadlineAt);

  factory AbsenceFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime fromTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final statusText =
        (map['status'] as String?)?.trim().toLowerCase() ?? 'pending';

    return AbsenceFeatureModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      teacherId: (map['teacherId'] as String?)?.trim() ?? '',
      teacherName:
          (map['teacherName'] as String?)?.trim() ??
          (map['teacher'] as String?)?.trim() ??
          'Unknown Teacher',
      subjectId: (map['subjectId'] as String?)?.trim() ?? '',
      subjectName:
          (map['subject'] as String?)?.trim() ??
          (map['subjectName'] as String?)?.trim() ??
          (map['courseName'] as String?)?.trim() ??
          'Unknown Subject',
      courseCode: (map['courseCode'] as String?)?.trim() ?? '-',
      courseName: (map['courseName'] as String?)?.trim() ?? 'Unknown Course',
      createdAt: fromTimestamp(map['createdAt']),
      deadlineAt: fromTimestamp(map['deadlineAt']),
      status: switch (statusText) {
        'approved' => AbsenceStatus.justified,
        'submitted' => AbsenceStatus.justified,
        'justified' => AbsenceStatus.justified,
        'expired' => AbsenceStatus.rejected,
        'rejected' => AbsenceStatus.rejected,
        _ => AbsenceStatus.pending,
      },
      justificationId: (map['justificationId'] as String?)?.trim(),
      submittedAt: map['submittedAt'] == null
          ? null
          : fromTimestamp(map['submittedAt']),
    );
  }
}
