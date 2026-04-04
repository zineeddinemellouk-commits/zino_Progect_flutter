class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.attendancePercentage,
    required this.groupId,
    required this.classId,
    required this.subjectIds,
    this.groupName,
    this.levelId,
  });

  final String id;
  final String fullName;
  final String email;
  final int attendancePercentage;
  final String groupId;
  final String classId;
  final List<String> subjectIds;
  final String? groupName;
  final String? levelId;

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      attendancePercentage: (map['attendancePercentage'] as num?)?.round() ?? 0,
      groupId: (map['groupId'] as String?)?.trim() ?? '',
      classId: (map['classId'] as String?)?.trim() ?? '',
      subjectIds: (map['subjectIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      levelId: (map['levelId'] as String?)?.trim(),
    );
  }

  StudentModel copyWith({
    String? id,
    String? fullName,
    String? email,
    int? attendancePercentage,
    String? groupId,
    String? classId,
    List<String>? subjectIds,
    String? groupName,
    String? levelId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      groupId: groupId ?? this.groupId,
      classId: classId ?? this.classId,
      subjectIds: subjectIds ?? this.subjectIds,
      groupName: groupName ?? this.groupName,
      levelId: levelId ?? this.levelId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'attendancePercentage': attendancePercentage,
      'groupId': groupId,
      'classId': classId,
      'subjectIds': subjectIds,
      if (levelId != null && levelId!.isNotEmpty) 'levelId': levelId,
    };
  }

}
