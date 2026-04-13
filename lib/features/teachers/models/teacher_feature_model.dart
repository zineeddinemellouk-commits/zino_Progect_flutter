import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherFeatureModel {
  const TeacherFeatureModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.subjectIds,
    required this.levelIds,
    required this.groupIds,
    required this.createdAt,
    required this.totalStudents,
    required this.totalLevels,
    required this.totalGroups,
    required this.pendingRequests,
    required this.attendanceRate,
  });

  final String id;
  final String fullName;
  final String email;
  final List<String> subjectIds;
  final List<String> levelIds;
  final List<String> groupIds;
  final DateTime createdAt;
  final int totalStudents;
  final int totalLevels;
  final int totalGroups;
  final int pendingRequests;
  final double attendanceRate;

  factory TeacherFeatureModel.fromMap(String id, Map<String, dynamic> map) {
    List<String> readList(String key, {List<String> fallback = const []}) {
      return (map[key] as List<dynamic>? ?? fallback)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    final legacyGroupIds = (map['classIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

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
      subjectIds: readList('subjectIds'),
      levelIds: readList('levelIds'),
      groupIds: readList('groupIds', fallback: legacyGroupIds),
      createdAt: createdAt,
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      totalLevels: (map['totalLevels'] as num?)?.toInt() ?? 0,
      totalGroups: (map['totalGroups'] as num?)?.toInt() ?? 0,
      pendingRequests: (map['pendingRequests'] as num?)?.toInt() ?? 0,
      attendanceRate: (map['attendanceRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'subjectIds': subjectIds,
      'levelIds': levelIds,
      'groupIds': groupIds,
      'totalStudents': totalStudents,
      'totalLevels': totalLevels,
      'totalGroups': totalGroups,
      'pendingRequests': pendingRequests,
      'attendanceRate': attendanceRate,
    };
  }
}
