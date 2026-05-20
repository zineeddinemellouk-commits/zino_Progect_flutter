import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  absenceRecorded,
  justificationSubmitted,
  absenceExpired,
  other,
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedAbsenceId,
    this.relatedJustificationId,
  });

  final String id;
  final String studentId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedAbsenceId;
  final String? relatedJustificationId;

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime fromTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final typeString = (map['type'] as String?)?.toLowerCase() ?? 'other';
    final type = switch (typeString) {
      'absencerecorded' => NotificationType.absenceRecorded,
      'justificationsubmitted' => NotificationType.justificationSubmitted,
      'absenceexpired' => NotificationType.absenceExpired,
      _ => NotificationType.other,
    };

    return NotificationModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      type: type,
      title: (map['title'] as String?)?.trim() ?? '',
      message: (map['message'] as String?)?.trim() ?? '',
      createdAt: fromTimestamp(map['createdAt']),
      isRead: (map['isRead'] as bool?) ?? false,
      relatedAbsenceId: (map['relatedAbsenceId'] as String?)?.trim(),
      relatedJustificationId: (map['relatedJustificationId'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'type': type.toString().split('.').last.toLowerCase(),
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      if (relatedAbsenceId != null) 'relatedAbsenceId': relatedAbsenceId,
      if (relatedJustificationId != null)
        'relatedJustificationId': relatedJustificationId,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? studentId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? relatedAbsenceId,
    String? relatedJustificationId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      relatedAbsenceId: relatedAbsenceId ?? this.relatedAbsenceId,
      relatedJustificationId:
          relatedJustificationId ?? this.relatedJustificationId,
    );
  }
}
