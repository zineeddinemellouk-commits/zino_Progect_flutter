import 'package:cloud_firestore/cloud_firestore.dart';

class StudentFeatureModel {
  const StudentFeatureModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.levelId,
    required this.groupId,
    required this.classId,
    required this.createdAt,
    required this.totalPresence,
    required this.totalAbsence,
    required this.justifiedAbsence,
    required this.pendingAbsence,
    required this.attendanceRate,
  });

  final String id;
  final String fullName;
  final String email;
  final String levelId;
  final String groupId;
  final String classId;
  final DateTime createdAt;
  final int totalPresence;
  final int totalAbsence;
  final int justifiedAbsence;
  final int pendingAbsence;
  final double attendanceRate;

  int get totalSessions => totalPresence + totalAbsence;

  factory StudentFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      createdAt = timestamp;
    } else {
      createdAt = DateTime.now();
    }

    final totalPresence = (map['totalPresence'] as num?)?.toInt() ?? 0;
    final totalAbsence = (map['totalAbsence'] as num?)?.toInt() ?? 0;

    final storedRate = (map['attendanceRate'] as num?)?.toDouble();
    final computedRate = (totalPresence + totalAbsence) == 0
        ? 0.0
        : totalPresence / (totalPresence + totalAbsence);

    return StudentFeatureModel(
      id: id,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      levelId: (map['levelId'] as String?)?.trim() ?? '',
      groupId: (map['groupId'] as String?)?.trim() ?? '',
      classId: (map['classId'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      totalPresence: totalPresence,
      totalAbsence: totalAbsence,
      justifiedAbsence: (map['justifiedAbsence'] as num?)?.toInt() ?? 0,
      pendingAbsence: (map['pendingAbsence'] as num?)?.toInt() ?? 0,
      attendanceRate: storedRate ?? computedRate,
    );
  }
}
