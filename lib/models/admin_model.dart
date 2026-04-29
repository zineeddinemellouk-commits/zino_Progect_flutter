class AdminModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool isActive;

  AdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt,
      'is_active': isActive,
    };
  }

  /// Create from Firestore document
  factory AdminModel.fromMap(Map<String, dynamic> map, String docId) {
    return AdminModel(
      id: map['id'] ?? docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'admin',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      isActive: map['is_active'] ?? true,
    );
  }
}
