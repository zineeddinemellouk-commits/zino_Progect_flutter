import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/services/role_manager.dart';

/// Secure authentication service that integrates role-based access control
/// This replaces the existing simple auth flow with a secure one
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firebaseFirestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firebaseFirestore;

  static const String _userProfileCollection = 'user_profile';

  /// Get current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user UID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Check if user is currently authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Login user with email and password
  /// This is the primary secure login flow
  Future<void> login({
    required String email,
    required String password,
    required RoleManager roleManager,
  }) async {
    try {
      // Attempt Firebase auth
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Unable to authenticate user.',
        );
      }

      // Initialize role manager to fetch and set the user's role
      // This will throw if user_profile doesn't exist or role is invalid
      await roleManager.initializeFromFirestore();

      if (roleManager.currentRole == UserRole.unknown) {
        await _firebaseAuth.signOut();
        throw FirebaseAuthException(
          code: 'invalid-role',
          message: 'User role is not configured. Contact administrator.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'login-error',
        message: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Create a new account with role
  /// IMPORTANT: Only department accounts can be auto-created via login
  Future<void> createAccountWithRole({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Unable to create account.',
        );
      }

      // Create user_profile document
      await _createUserProfile(
        uid: user.uid,
        email: email.trim(),
        role: role,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'account-creation-error',
        message: 'Account creation failed: ${e.toString()}',
      );
    }
  }

  /// Internal method to create user_profile document
  /// CRITICAL: This is where the role is permanently stored
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String role,
    String displayName = '',
  }) async {
    try {
      final userRole = UserRoleExtension.fromString(role);
      if (userRole == UserRole.unknown) {
        throw FirebaseException(
          plugin: 'auth_service',
          code: 'invalid-role',
          message: 'Invalid role: $role',
        );
      }

      await _firebaseFirestore.collection(_userProfileCollection).doc(uid).set({
        'email': email.trim(),
        'role': role.trim(),
        'displayName': displayName.isNotEmpty
            ? displayName
            : '${userRole.displayName} User',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  /// Get user role safely
  /// CRITICAL: Always use this to verify role from user_profile
  Future<UserRole> getUserRole(String uid) async {
    try {
      final docSnapshot = await _firebaseFirestore
          .collection(_userProfileCollection)
          .doc(uid)
          .get();

      if (!docSnapshot.exists) {
        return UserRole.unknown;
      }

      final roleString = docSnapshot.data()?['role'] as String?;
      return UserRoleExtension.fromString(roleString);
    } catch (e) {
      throw Exception('Failed to verify user role: ${e.toString()}');
    }
  }

  /// Verify that the logged-in user matches expected role
  /// Use this for additional security checks
  Future<bool> verifyUserRole(String expectedRole) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    try {
      final actualRole = await getUserRole(user.uid);
      final expectedUserRole = UserRoleExtension.fromString(expectedRole);
      return actualRole == expectedUserRole;
    } catch (_) {
      return false;
    }
  }

  /// Logout user and clear role
  Future<void> logout({RoleManager? roleManager}) async {
    try {
      // Clear role manager if provided
      roleManager?.clearRole();

      // Sign out from Firebase
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'reset-email-error',
        message: 'Failed to send password reset email: ${e.toString()}',
      );
    }
  }

  /// Delete user account and profile
  /// WARNING: This is a destructive operation
  Future<void> deleteAccount({required String uid}) async {
    try {
      // Delete user_profile document
      await _firebaseFirestore
          .collection(_userProfileCollection)
          .doc(uid)
          .delete();

      // Delete Firebase auth account
      final user = _firebaseAuth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? email,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
      }

      if (email != null) {
        updateData['email'] = email.trim();
      }

      await _firebaseFirestore
          .collection(_userProfileCollection)
          .doc(uid)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }

  /// Stream user role changes (for real-time role updates)
  Stream<UserRole> streamUserRole(String uid) {
    return _firebaseFirestore
        .collection(_userProfileCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          final roleString = snapshot.data()?['role'] as String?;
          return UserRoleExtension.fromString(roleString);
        });
  }
}
