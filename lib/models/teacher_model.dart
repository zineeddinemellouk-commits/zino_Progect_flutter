class TeacherModel {
  const TeacherModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.subjectIds,
    required this.levelIds,
    required this.groupIds,
  });

  final String id;
  final String fullName;
  final String email;
  final List<String> subjectIds;
  final List<String> levelIds;
  final List<String> groupIds;

  factory TeacherModel.fromMap(String id, Map<String, dynamic> map) {
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

    return TeacherModel(
      id: id,
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      email: (map['email'] as String?)?.trim() ?? '',
      subjectIds: readList('subjectIds'),
      levelIds: readList('levelIds'),
      groupIds: readList('groupIds', fallback: legacyGroupIds),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'subjectIds': subjectIds,
      'levelIds': levelIds,
      'groupIds': groupIds,
    };
  }
}
