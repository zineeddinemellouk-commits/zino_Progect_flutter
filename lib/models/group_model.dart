class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.levelId,
  });

  final String id;
  final String name;
  final String levelId;

  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: (map['name'] as String?)?.trim() ?? '',
      levelId: (map['levelId'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'levelId': levelId};
  }
}
