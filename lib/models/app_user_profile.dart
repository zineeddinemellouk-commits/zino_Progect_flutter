class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    required this.linkedCollection,
    required this.linkedDocumentId,
  });

  final String uid;
  final String email;
  final String role;
  final String displayName;
  final String linkedCollection;
  final String linkedDocumentId;

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserProfile(
      uid: uid,
      email: (map['email'] as String?)?.trim() ?? '',
      role: (map['role'] as String?)?.trim() ?? '',
      displayName: (map['displayName'] as String?)?.trim() ?? '',
      linkedCollection: (map['linkedCollection'] as String?)?.trim() ?? '',
      linkedDocumentId: (map['linkedDocumentId'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email.trim(),
      'role': role.trim(),
      'displayName': displayName.trim(),
      'linkedCollection': linkedCollection.trim(),
      'linkedDocumentId': linkedDocumentId.trim(),
    };
  }
}
