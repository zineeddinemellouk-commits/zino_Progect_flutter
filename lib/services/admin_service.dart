import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/models/admin_model.dart';

class AdminService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new admin user
  /// 
  /// This function:
  /// 1. Creates a new user in Firebase Auth
  /// 2. Stores admin details in Firestore 'department_admins' collection
  /// 3. Returns the created AdminModel
  Future<AdminModel> createAdmin({
    required String fullName,
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    try {
      // Validate inputs
      _validateInputs(fullName, email, password);

      // Check if email already exists
      await _checkEmailExists(email);

      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final userId = userCredential.user!.uid;

      // Create admin record in Firestore
      final admin = AdminModel(
        id: userId,
        name: fullName.trim(),
        email: email.trim().toLowerCase(),
        role: role.toLowerCase(),
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Store in Firestore
      await _firestore
          .collection('department_admins')
          .doc(userId)
          .set(admin.toMap());

      return admin;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to create admin: ${e.toString()}');
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool _isStrongPassword(String password) {
    return password.length >= 6;
  }

  /// Validate all inputs
  void _validateInputs(String fullName, String email, String password) {
    if (fullName.trim().isEmpty) {
      throw Exception('Full name cannot be empty');
    }

    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }

    if (!_isStrongPassword(password)) {
      throw Exception('Password must be at least 6 characters');
    }
  }

  /// Check if email already exists in Firestore
  Future<void> _checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('department_admins')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        throw Exception('Email already exists');
      }
    } catch (e) {
      if (e.toString().contains('already exists')) {
        rethrow;
      }
      throw Exception('Failed to check email: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Account creation is disabled';
      case 'user-disabled':
        return 'User account has been disabled';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  /// Get all admins (for admin management page)
  Stream<List<AdminModel>> watchAdmins() {
    return _firestore
        .collection('department_admins')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AdminModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get admin by ID
  Future<AdminModel?> getAdminById(String adminId) async {
    try {
      final doc =
          await _firestore.collection('department_admins').doc(adminId).get();

      if (doc.exists && doc.data() != null) {
        return AdminModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch admin: ${e.toString()}');
    }
  }

  /// Deactivate an admin (soft delete)
  Future<void> deactivateAdmin(String adminId) async {
    try {
      await _firestore
          .collection('department_admins')
          .doc(adminId)
          .update({'is_active': false});
    } catch (e) {
      throw Exception('Failed to deactivate admin: ${e.toString()}');
    }
  }

  /// Delete an admin permanently
  Future<void> deleteAdmin(String adminId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('department_admins').doc(adminId).delete();

      // Delete from Firebase Auth
      // Note: This requires admin SDK privileges
      // For now, we'll just disable the account
      await deactivateAdmin(adminId);
    } catch (e) {
      throw Exception('Failed to delete admin: ${e.toString()}');
    }
  }
}
