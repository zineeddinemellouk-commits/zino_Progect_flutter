import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Enum for user roles - single source of truth
enum UserRole {
  student,
  teacher,
  department,
  unknown,
}

/// Extension to convert string to enum
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.department:
        return 'Department';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.department:
        return 'department';
      case UserRole.unknown:
        return 'unknown';
    }
  }

  static UserRole fromString(String? roleString) {
    if (roleString == null) return UserRole.unknown;
    final lower = roleString.toLowerCase().trim();
    
    switch (lower) {
      case 'student':
        return UserRole.student;
      case 'teacher':
        return UserRole.teacher;
      case 'department':
        return UserRole.department;
      default:
        return UserRole.unknown;
    }
  }
}

/// Central role manager - handles all role-related operations
/// This is a ChangeNotifier so the app can reactively update when role changes
class RoleManager extends ChangeNotifier {
  RoleManager({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  static const String _userProfileCollection = 'user_profile';

  // Current state
  UserRole? _currentRole;
  String? _currentUserId;
  String? _currentUserEmail;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserRole? get currentRole => _currentRole;
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Convenience getters for role checking
  bool get isStudent => _currentRole == UserRole.student;
  bool get isTeacher => _currentRole == UserRole.teacher;
  bool get isDepartment => _currentRole == UserRole.department;
  bool get isAuthenticated => _currentUserId != null && _currentRole != null;

  /// Initialize role manager - call this after auth is successful
  /// This fetches the actual role from Firestore
  Future<void> initializeFromFirestore() async {
    try {
      _setLoading(true);
      _clearError();

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        _setError('No authenticated user found');
        _setLoading(false);
        notifyListeners();
        return;
      }

      _currentUserId = user.uid;
      _currentUserEmail = user.email;

      // Fetch role from user_profile collection
      final role = await _fetchRoleFromFirestore(user.uid);
      _currentRole = role;

      if (role == UserRole.unknown) {
        _setError('User profile not found or role is invalid');
      }

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize role: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch role from Firestore user_profile collection
  /// CRITICAL: Role is ONLY read from user_profile, nowhere else
  Future<UserRole> _fetchRoleFromFirestore(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_userProfileCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        throw FirebaseException(
          plugin: 'role_manager',
          code: 'user_profile_not_found',
          message: 'No user_profile document found for UID: $uid',
        );
      }

      final data = docSnapshot.data();
      if (data == null) {
        throw FirebaseException(
          plugin: 'role_manager',
          code: 'user_profile_data_null',
          message: 'user_profile document exists but has no data',
        );
      }

      final roleString = data['role'] as String?;
      if (roleString == null || roleString.trim().isEmpty) {
        throw FirebaseException(
          plugin: 'role_manager',
          code: 'role_field_missing',
          message: 'user_profile document missing or empty "role" field',
        );
      }

      return UserRoleExtension.fromString(roleString);
    } catch (e) {
      if (e is FirebaseException) rethrow;
      throw FirebaseException(
        plugin: 'role_manager',
        code: 'role_fetch_error',
        message: 'Error fetching role from Firestore: ${e.toString()}',
      );
    }
  }

  /// Check if the current user has a specific role
  /// Use this to protect screen access
  bool hasRole(UserRole role) {
    return _currentRole == role;
  }

  /// Check if the current user has one of multiple roles
  bool hasAnyRole(List<UserRole> roles) {
    return _currentRole != null && roles.contains(_currentRole);
  }

  /// Clear role data (call on logout)
  void clearRole() {
    _currentRole = null;
    _currentUserId = null;
    _currentUserEmail = null;
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}
