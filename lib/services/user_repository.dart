import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/services/role_manager.dart';

/// Repository for fetching role-specific user data
/// This ensures that users only access data from their role's collection
class UserRepository {
  UserRepository({
    FirebaseFirestore? firebaseFirestore,
  }) : _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firebaseFirestore;

  // Collection names
  static const String _userProfileCollection = 'user_profile';
  static const String _studentCollection = 'student';
  static const String _teacherCollection = 'teacher';
  static const String _departmentCollection = 'department';

  /// Get the collection name for a given role
  static String getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return _studentCollection;
      case UserRole.teacher:
        return _teacherCollection;
      case UserRole.department:
        return _departmentCollection;
      case UserRole.unknown:
        throw Exception('Cannot get collection for unknown role');
    }
  }

  /// Fetch user profile by UID
  /// SECURITY: This method verifies the user exists in user_profile
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_userProfileCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('User profile not found for UID: $uid');
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw Exception('User profile exists but has no data');
      }

      return data;
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// Fetch student data by UID
  /// Only callable when user role is verified as 'student'
  Future<Map<String, dynamic>?> getStudentData(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_studentCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return docSnapshot.data();
    } catch (e) {
      throw Exception('Failed to fetch student data: ${e.toString()}');
    }
  }

  /// Fetch teacher data by UID
  /// Only callable when user role is verified as 'teacher'
  Future<Map<String, dynamic>?> getTeacherData(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_teacherCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return docSnapshot.data();
    } catch (e) {
      throw Exception('Failed to fetch teacher data: ${e.toString()}');
    }
  }

  /// Fetch department data by UID
  /// Only callable when user role is verified as 'department'
  Future<Map<String, dynamic>?> getDepartmentData(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_departmentCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return docSnapshot.data();
    } catch (e) {
      throw Exception('Failed to fetch department data: ${e.toString()}');
    }
  }

  /// Fetch role-specific data based on the role passed in
  /// SECURITY: Caller must ensure they're fetching data for the correct role
  Future<Map<String, dynamic>?> getRoleSpecificData(
    String uid,
    UserRole role,
  ) async {
    switch (role) {
      case UserRole.student:
        return getStudentData(uid);
      case UserRole.teacher:
        return getTeacherData(uid);
      case UserRole.department:
        return getDepartmentData(uid);
      case UserRole.unknown:
        throw Exception('Cannot fetch data for unknown role');
    }
  }

  /// Stream student data (for real-time updates)
  Stream<Map<String, dynamic>?> streamStudentData(String uid) {
    return _firebaseFirestore
        .collection(_studentCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream teacher data (for real-time updates)
  Stream<Map<String, dynamic>?> streamTeacherData(String uid) {
    return _firebaseFirestore
        .collection(_teacherCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream department data (for real-time updates)
  Stream<Map<String, dynamic>?> streamDepartmentData(String uid) {
    return _firebaseFirestore
        .collection(_departmentCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Stream role-specific data based on role
  Stream<Map<String, dynamic>?> streamRoleSpecificData(
    String uid,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.student:
        return streamStudentData(uid);
      case UserRole.teacher:
        return streamTeacherData(uid);
      case UserRole.department:
        return streamDepartmentData(uid);
      case UserRole.unknown:
        throw Exception('Cannot stream data for unknown role');
    }
  }
}
