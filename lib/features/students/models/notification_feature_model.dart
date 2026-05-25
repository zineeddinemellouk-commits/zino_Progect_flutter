import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// Notification Feature Model
// Represents student-facing notifications
// for absences, justifications, and reviews.
// ========================================

enum NotificationFeatureType {
  absenceRecorded,
  justificationSubmitted,
  absenceExpired,
  exclusionPending,
  exclusionApproved,
  exclusionRejected,
  justificationAccepted,
  justificationRejected,
  other,
}

class NotificationFeatureModel {
  const NotificationFeatureModel({
    required this.id,
    required this.studentId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedAbsenceId,
    this.relatedJustificationId,
    this.relatedExclusionId,
  });

  final String id;
  final String studentId;
  final NotificationFeatureType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedAbsenceId;
  final String? relatedJustificationId;
  final String? relatedExclusionId;

  static String _normalizeType(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static NotificationFeatureType _typeFromString(String value) {
    return switch (_normalizeType(value)) {
      'absencerecorded' => NotificationFeatureType.absenceRecorded,
      'justificationsubmitted' => NotificationFeatureType.justificationSubmitted,
      'absenceexpired' => NotificationFeatureType.absenceExpired,
      'exclusionpending' => NotificationFeatureType.exclusionPending,
      'exclusionapproved' => NotificationFeatureType.exclusionApproved,
      'exclusionrejected' => NotificationFeatureType.exclusionRejected,
      'justificationaccepted' => NotificationFeatureType.justificationAccepted,
      'justificationrejected' => NotificationFeatureType.justificationRejected,
      _ => NotificationFeatureType.other,
    };
  }

  factory NotificationFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime fromTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final type = _typeFromString((map['type'] as String?) ?? 'other');

    return NotificationFeatureModel(
      id: id,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      type: type,
      title: (map['title'] as String?)?.trim() ?? '',
      message: (map['message'] as String?)?.trim() ?? '',
      createdAt: fromTimestamp(map['createdAt']),
      isRead: (map['isRead'] as bool?) ?? false,
      relatedAbsenceId: (map['relatedAbsenceId'] as String?)?.trim(),
      relatedJustificationId: (map['relatedJustificationId'] as String?)?.trim(),
      relatedExclusionId: (map['relatedExclusionId'] as String?)?.trim(),
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
      if (relatedExclusionId != null) 'relatedExclusionId': relatedExclusionId,
    };
  }

  NotificationFeatureModel copyWith({
    String? id,
    String? studentId,
    NotificationFeatureType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? relatedAbsenceId,
    String? relatedJustificationId,
    String? relatedExclusionId,
  }) {
    return NotificationFeatureModel(
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
      relatedExclusionId: relatedExclusionId ?? this.relatedExclusionId,
    );
  }
}
