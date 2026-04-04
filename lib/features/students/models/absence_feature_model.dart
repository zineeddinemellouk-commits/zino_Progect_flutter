import 'package:cloud_firestore/cloud_firestore.dart';

enum AbsenceStatus { pending, justified, rejected }

class AbsenceFeatureModel {
  const AbsenceFeatureModel({
    required this.id,
    required this.studentId,
    required this.createdAt,
    required this.deadlineAt,
    required this.status,
    required this.courseCode,
    required this.courseName,
  });

  final String id;
  final String studentId;
  final DateTime createdAt;
  final DateTime deadlineAt;
  final AbsenceStatus status;
  final String courseCode;
  final String courseName;

  bool get isExpired =>
      status == AbsenceStatus.rejected || DateTime.now().isAfter(deadlineAt);

  factory AbsenceFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime fromTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final statusText = (map['status'] as String?)?.trim().toLowerCase() ?? 'pending';

    return AbsenceFeatureModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      createdAt: fromTimestamp(map['createdAt']),
      deadlineAt: fromTimestamp(map['deadlineAt']),
      status: switch (statusText) {
        'justified' => AbsenceStatus.justified,
        'rejected' => AbsenceStatus.rejected,
        _ => AbsenceStatus.pending,
      },
      courseCode: (map['courseCode'] as String?)?.trim() ?? '-',
      courseName: (map['courseName'] as String?)?.trim() ?? 'Unknown Course',
    );
  }
}
