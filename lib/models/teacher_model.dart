class TeacherModel {
  const TeacherModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.subjectIds,
  });

  final String id;
  final String fullName;
  final String email;
  final List<String> subjectIds;

  factory TeacherModel.fromMap(String id, Map<String, dynamic> map) {
    return TeacherModel(
      id: id,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      subjectIds: (map['subjectIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'subjectIds': subjectIds,
    };
  }
}
