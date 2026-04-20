import 'package:cloud_firestore/cloud_firestore.dart';

enum DepartmentNotificationType {
  justificationSubmitted,
  justificationApproved,
  justificationRejected,
}

class DepartmentNotificationModel {
  const DepartmentNotificationModel({
    required this.id,
    required this.departmentId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.studentId,
    required this.studentName,
    required this.justificationId,
    required this.absenceId,
    required this.subjectName,
    this.photoUrl,
  });

  final String id;
  final String departmentId;
  final DepartmentNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String studentId;
  final String studentName;
  final String justificationId;
  final String absenceId;
  final String subjectName;
  final String? photoUrl;

  factory DepartmentNotificationModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    DateTime fromTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    final typeString = (map['type'] as String?)?.toLowerCase() ?? 'other';
    final type = switch (typeString) {
      'justificationsubmitted' =>
        DepartmentNotificationType.justificationSubmitted,
      'justificationapproved' =>
        DepartmentNotificationType.justificationApproved,
      'justificationrejected' =>
        DepartmentNotificationType.justificationRejected,
      _ => DepartmentNotificationType.justificationSubmitted,
    };

    return DepartmentNotificationModel(
      id: id,
      departmentId: (map['departmentId'] as String?)?.trim() ?? '',
      type: type,
      title: (map['title'] as String?)?.trim() ?? '',
      message: (map['message'] as String?)?.trim() ?? '',
      createdAt: fromTimestamp(map['createdAt']),
      isRead: (map['isRead'] as bool?) ?? false,
      studentId: (map['studentId'] as String?)?.trim() ?? '',
      studentName: (map['studentName'] as String?)?.trim() ?? '',
      justificationId: (map['justificationId'] as String?)?.trim() ?? '',
      absenceId: (map['absenceId'] as String?)?.trim() ?? '',
      subjectName: (map['subjectName'] as String?)?.trim() ?? '',
      photoUrl: (map['photoUrl'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'type': type.toString().split('.').last.toLowerCase(),
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'studentId': studentId,
      'studentName': studentName,
      'justificationId': justificationId,
      'absenceId': absenceId,
      'subjectName': subjectName,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  DepartmentNotificationModel copyWith({
    String? id,
    String? departmentId,
    DepartmentNotificationType? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? studentId,
    String? studentName,
    String? justificationId,
    String? absenceId,
    String? subjectName,
    String? photoUrl,
  }) {
    return DepartmentNotificationModel(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      justificationId: justificationId ?? this.justificationId,
      absenceId: absenceId ?? this.absenceId,
      subjectName: subjectName ?? this.subjectName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
    }
  }
}
