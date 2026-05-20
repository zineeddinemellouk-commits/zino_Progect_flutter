import 'package:cloud_firestore/cloud_firestore.dart';

enum ExclusionStatus { pending, approved, rejected }

class ExclusionModel {
  const ExclusionModel({
    required this.id,
    required this.studentId,
    required this.studentDocId,
    required this.studentName,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subjectName,
    required this.levelId,
    required this.levelName,
    required this.groupId,
    required this.groupName,
    required this.totalAbsences,
    required this.justifiedAbsences,
    required this.unjustifiedAbsences,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String studentDocId;
  final String studentName;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String subjectName;
  final String levelId;
  final String levelName;
  final String groupId;
  final String groupName;
  final int totalAbsences;
  final int justifiedAbsences;
  final int unjustifiedAbsences;
  final ExclusionStatus status;
  final DateTime createdAt;

  factory ExclusionModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is DateTime) return raw;
      return DateTime.now();
    }

    final statusText =
        (map['status'] as String?)?.trim().toLowerCase() ?? 'pending';

    return ExclusionModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      studentDocId: (map['studentDocId'] as String?)?.trim() ?? '',
      studentName: (map['studentName'] as String?)?.trim() ?? 'Unknown Student',
      teacherId: (map['teacherId'] as String?)?.trim() ?? '',
      teacherName: (map['teacherName'] as String?)?.trim() ?? 'Unknown Teacher',
      subjectId: (map['subjectId'] as String?)?.trim() ?? '',
      subjectName: (map['subjectName'] as String?)?.trim() ?? 'Unknown Subject',
      levelId: (map['levelId'] as String?)?.trim() ?? '',
      levelName: (map['levelName'] as String?)?.trim() ?? '-',
      groupId: (map['groupId'] as String?)?.trim() ?? '',
      groupName: (map['groupName'] as String?)?.trim() ?? '-',
      totalAbsences: (map['totalAbsences'] as num?)?.toInt() ?? 0,
      justifiedAbsences: (map['justifiedAbsences'] as num?)?.toInt() ?? 0,
      unjustifiedAbsences: (map['unjustifiedAbsences'] as num?)?.toInt() ?? 0,
      status: switch (statusText) {
        'approved' => ExclusionStatus.approved,
        'rejected' => ExclusionStatus.rejected,
        _ => ExclusionStatus.pending,
      },
      createdAt: parseDate(map['createdAt']),
    );
  }

  String get statusLabel => switch (status) {
    ExclusionStatus.pending => 'pending',
    ExclusionStatus.approved => 'approved',
    ExclusionStatus.rejected => 'rejected',
  };
}
