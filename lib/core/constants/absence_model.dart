import 'package:cloud_firestore/cloud_firestore.dart';

class AbsenceModel {
  const AbsenceModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.classId,
    required this.absenceDate,
    required this.courseCode,
    required this.courseName,
    this.status = 'pending',
    this.justifiedAt,
    this.justificationId,
  });

  final String id;
  final String studentId;
  final String subjectId;
  final String classId;
  final DateTime absenceDate;
  final String courseCode;
  final String courseName;
  final String status; // 'pending', 'justified', 'expired'
  final DateTime? justifiedAt;
  final String? justificationId;

  /// Calculates the remaining time in milliseconds before the 72-hour deadline expires.
  int get remainingMilliseconds {
    final deadline = absenceDate.add(const Duration(hours: 72));
    final remaining = deadline.difference(DateTime.now());
    return remaining.inMilliseconds > 0 ? remaining.inMilliseconds : 0;
  }

  /// Returns the remaining time as a human-readable string (e.g., "02h 45m remaining").
  String get remainingTimeFormatted {
    if (status == 'expired') return 'EXPIRED';
    if (status == 'justified') return 'JUSTIFIED';

    final remaining = remainingMilliseconds;
    if (remaining <= 0) return 'EXPIRED';

    final duration = Duration(milliseconds: remaining);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m remaining';
  }

  /// Determines if the absence is urgent (less than 24 hours remaining).
  bool get isUrgent => remainingMilliseconds < 86400000 && status != 'expired' && status != 'justified';

  factory AbsenceModel.fromMap(String id, Map<String, dynamic> map) {
    final absenceDate = map['absenceDate'];
    DateTime parsedAbsenceDate;
    if (absenceDate is Timestamp) {
      parsedAbsenceDate = absenceDate.toDate();
    } else if (absenceDate is DateTime) {
      parsedAbsenceDate = absenceDate;
    } else {
      parsedAbsenceDate = DateTime.now();
    }

    final justifiedAt = map['justifiedAt'];
    DateTime? parsedJustifiedAt;
    if (justifiedAt is Timestamp) {
      parsedJustifiedAt = justifiedAt.toDate();
    } else if (justifiedAt is DateTime) {
      parsedJustifiedAt = justifiedAt;
    }

    return AbsenceModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      subjectId: (map['subjectId'] as String?)?.trim() ?? '',
      classId: (map['classId'] as String?)?.trim() ?? '',
      absenceDate: parsedAbsenceDate,
      courseCode: (map['courseCode'] as String?)?.trim() ?? '',
      courseName: (map['courseName'] as String?)?.trim() ?? '',
      status: (map['status'] as String?)?.trim() ?? 'pending',
      justifiedAt: parsedJustifiedAt,
      justificationId: (map['justificationId'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'classId': classId,
      'absenceDate': Timestamp.fromDate(absenceDate),
      'courseCode': courseCode,
      'courseName': courseName,
      'status': status,
      if (justifiedAt != null) 'justifiedAt': Timestamp.fromDate(justifiedAt!),
      if (justificationId != null) 'justificationId': justificationId,
    };
  }

  AbsenceModel copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? classId,
    DateTime? absenceDate,
    String? courseCode,
    String? courseName,
    String? status,
    DateTime? justifiedAt,
    String? justificationId,
  }) {
    return AbsenceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
      absenceDate: absenceDate ?? this.absenceDate,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      status: status ?? this.status,
      justifiedAt: justifiedAt ?? this.justifiedAt,
      justificationId: justificationId ?? this.justificationId,
    );
  }
}
