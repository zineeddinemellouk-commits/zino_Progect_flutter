import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================================
/// SEPARATE AUTH STATE MANAGEMENT - INDEPENDENT FROM LOCALIZATION
/// ============================================================================
///
/// Key Principle:
/// - Auth state is managed INDEPENDENTLY from language/locale state
/// - Auth state changes do NOT cause language changes
/// - Language changes do NOT affect Firebase Auth session
///
/// This separation prevents logout when language changes.

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool _isInitialized = false;
  String? _userRole;
  Map<String, dynamic>? _userProfile;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Initialize auth state listener (call once in main)
  /// This DOES NOT mix with localization state
  void initializeAuthListener() {
    if (_isInitialized) return;

    _firebaseAuth.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userRole = null;
        _userProfile = null;
      }
      notifyListeners();
      debugPrint('🔐 Auth state changed: ${user?.email ?? "Logged out"}');
    });

    _isInitialized = true;
  }

  /// Load user profile data WITHOUT affecting localization
  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(uid).get();
      if (doc.exists) {
        _userProfile = doc.data();
        _userRole = _userProfile?['role'] as String?;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    }
  }

  /// Sign out - ONLY affects auth, NOT localization
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      _currentUser = null;
      _userRole = null;
      _userProfile = null;
      notifyListeners();
      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Signout error: $e');
      rethrow;
    }
  }

  /// Verify user is still authenticated
  /// Call this before sensitive operations to ensure session is valid
  bool verifyAuthSession() {
    final isValid = _firebaseAuth.currentUser != null;
    if (!isValid) {
      debugPrint('⚠️  Auth session invalid');
    }
    return isValid;
  }
}
