// ========================================
// Level Model
// Represents an academic level such as L1,
// L2, L3, M1, or M2.
// ========================================

class LevelModel {
  const LevelModel({required this.id, required this.name});

  final String id;
  final String name;

  factory LevelModel.fromMap(String id, Map<String, dynamic> map) {
    return LevelModel(
      id: id,
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : id,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name.trim()};
  }
}
