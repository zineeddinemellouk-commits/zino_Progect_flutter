class StudentModel {
  const StudentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.attendancePercentage,
    required this.groupId,
    this.groupName,
    this.levelId,
  });

  final String id;
  final String fullName;
  final String email;
  final int attendancePercentage;
  final String groupId;
  final String? groupName;
  final String? levelId;

  StudentModel copyWith({
    String? id,
    String? fullName,
    String? email,
    int? attendancePercentage,
    String? groupId,
    String? groupName,
    String? levelId,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      levelId: levelId ?? this.levelId,
    );
  }

}
