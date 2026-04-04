class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.teacherId,
    required this.classIds,
  });

  final String id;
  final String name;
  final String teacherId;
  final List<String> classIds;

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      teacherId: (map['teacherId'] as String?)?.trim() ?? '',
      classIds: (map['classIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'teacherId': teacherId,
      'classIds': classIds,
    };
  }
}
