import 'package:cloud_firestore/cloud_firestore.dart';

class JustificationModel {
  const JustificationModel({
    required this.id,
    required this.absenceId,
    required this.studentId,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.subject,
    required this.absenceDate,
    required this.fileUrl,
    required this.fileType,
    required this.createdAt,
    required this.status,
    this.reason,
    this.refusalReason,
    this.studentName,
    this.levelName,
    this.groupName,
    this.email,
  });

  final String id;
  final String absenceId;
  final String studentId;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String subject;
  final DateTime absenceDate;
  final String fileUrl;
  final String fileType;
  final DateTime createdAt;
  final String status;
  final String? reason;
  final String? refusalReason;

  // Optional denormalized display fields to keep current UI unchanged.
  final String? studentName;
  final String? levelName;
  final String? groupName;
  final String? email;

  factory JustificationModel.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else {
      createdAt = DateTime.now();
    }

    return JustificationModel(
      id: id,
      absenceId: (map['absenceId'] as String?)?.trim() ?? '',
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      teacherId: (map['teacherId'] as String?)?.trim() ?? '',
      teacherName: (map['teacherName'] as String?)?.trim() ?? 'Unknown Teacher',
      subjectId: (map['subjectId'] as String?)?.trim() ?? '',
      subject: (map['subject'] as String?)?.trim() ?? (map['subjectName'] as String?)?.trim() ?? 'Unknown Subject',
      absenceDate: (() {
        final raw = map['absenceDate'];
        if (raw is Timestamp) return raw.toDate();
        if (raw is DateTime) return raw;
        return createdAt;
      })(),
      fileUrl: (map['fileUrl'] as String?)?.trim() ?? '',
      fileType: (map['fileType'] as String?)?.trim() ?? '',
      createdAt: createdAt,
      status: (map['status'] as String?)?.trim() ?? 'pending',
      reason: (map['reason'] as String?)?.trim(),
      refusalReason: (map['refusalReason'] as String?)?.trim(),
      studentName: (map['studentName'] as String?)?.trim(),
      levelName: (map['levelName'] as String?)?.trim(),
      groupName: (map['groupName'] as String?)?.trim(),
      email: (map['email'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'absenceId': absenceId,
      'studentId': studentId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectId': subjectId,
      'subject': subject,
      'absenceDate': Timestamp.fromDate(absenceDate),
      'fileUrl': fileUrl,
      'fileType': fileType,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (reason != null) 'reason': reason,
      if (refusalReason != null) 'refusalReason': refusalReason,
      if (studentName != null) 'studentName': studentName,
      if (levelName != null) 'levelName': levelName,
      if (groupName != null) 'groupName': groupName,
      if (email != null) 'email': email,
    };
  }
}
