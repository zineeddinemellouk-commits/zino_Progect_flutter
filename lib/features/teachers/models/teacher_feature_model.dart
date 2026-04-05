import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherFeatureModel {
  const TeacherFeatureModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.subjectIds,
    required this.classIds,
    required this.createdAt,
    required this.totalStudents,
    required this.totalClasses,
    required this.pendingRequests,
    required this.attendanceRate,
  });

  final String id;
  final String fullName;
  final String email;
  final List<String> subjectIds;
  final List<String> classIds;
  final DateTime createdAt;
  final int totalStudents;
  final int totalClasses;
  final int pendingRequests;
  final double attendanceRate;

  factory TeacherFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];
    DateTime createdAt;
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      createdAt = timestamp;
    } else {
      createdAt = DateTime.now();
    }

    return TeacherFeatureModel(
      id: id,
      fullName:
          (map['fullName'] as String?)?.trim() ??
          (map['name'] as String?)?.trim() ??
          '',
      email: (map['email'] as String?)?.trim() ?? '',
      subjectIds: (map['subjectIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      classIds: (map['classIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      createdAt: createdAt,
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      totalClasses: (map['totalClasses'] as num?)?.toInt() ?? 0,
      pendingRequests: (map['pendingRequests'] as num?)?.toInt() ?? 0,
      attendanceRate: (map['attendanceRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'subjectIds': subjectIds,
      'classIds': classIds,
      'totalStudents': totalStudents,
      'totalClasses': totalClasses,
      'pendingRequests': pendingRequests,
      'attendanceRate': attendanceRate,
    };
  }
}
