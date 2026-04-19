import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/services/role_manager.dart';

/// Result type for role operations
class RoleCheckResult {
  const RoleCheckResult({
    required this.hasAccess,
    required this.currentRole,
    this.requiredRoles,
    this.error,
    this.isInitialized = false,
    this.isLoading = false,
  });

  final bool hasAccess;
  final UserRole? currentRole;
  final List<UserRole>? requiredRoles;
  final String? error;
  final bool isInitialized;
  final bool isLoading;

  /// Convenience getter for access message
  String get accessMessage {
    if (!isInitialized) {
      return 'Verifying your access...';
    }
    if (error != null) {
      return error!;
    }
    if (!hasAccess) {
      return 'You do not have permission to access this section.';
    }
    return 'Access granted';
  }

  @override
  String toString() =>
      'RoleCheckResult(hasAccess: $hasAccess, role: ${currentRole?.displayName}, error: $error)';
}

/// Safe role checking service with comprehensive error handling
/// Handles all edge cases: null roles, loading states, Firebase errors, etc.
class RoleCheckService {
  static final _instance = RoleCheckService._internal();

  factory RoleCheckService() {
    return _instance;
  }

  RoleCheckService._internal() {
    _firebaseFirestore = FirebaseFirestore.instance;
  }

  late final FirebaseFirestore _firebaseFirestore;

  /// Check if current user has a specific role
  /// Safe version that handles all error cases
  static RoleCheckResult checkUserRole(
    BuildContext context, {
    required UserRole requiredRole,
  }) {
    try {
      // Check context
      if (!context.mounted) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Unable to verify permissions - context unavailable',
        );
      }

      // Get role manager
      final roleManager = context.read<RoleManager>();

      // Check if still loading
      if (roleManager.isLoading && !roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          isLoading: true,
          error: 'Verifying your role...',
        );
      }

      // Check if there's an error
      if (roleManager.error != null && !roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Error verifying role: ${roleManager.error}',
        );
      }

      // Check if role is initialized
      if (!roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Your role information is not available. Please try again.',
        );
      }

      // Check if authenticated
      if (!roleManager.isAuthenticated) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'You are not authenticated. Please log in.',
        );
      }

      // Get current role
      final currentRole = roleManager.currentRole;

      // Check if role is unknown
      if (currentRole == UserRole.unknown || currentRole == null) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: currentRole,
          error: 'Your role could not be determined. Please log in again.',
        );
      }

      // Check permission
      final hasAccess = currentRole == requiredRole;

      if (!hasAccess) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: currentRole,
          requiredRoles: [requiredRole],
          error: 'Access denied. You are logged in as ${currentRole.displayName}.\n'
              'This section requires a ${requiredRole.displayName} account.',
        );
      }

      return RoleCheckResult(
        hasAccess: true,
        currentRole: currentRole,
        requiredRoles: [requiredRole],
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('[RoleCheck] Unexpected error: $e');
      return RoleCheckResult(
        hasAccess: false,
        currentRole: null,
        error: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Check if current user has ANY of the provided roles
  /// Safe version for checking multiple allowed roles
  static RoleCheckResult checkUserRoleMultiple(
    BuildContext context, {
    required List<UserRole> allowedRoles,
  }) {
    try {
      if (!context.mounted) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Unable to verify permissions',
        );
      }

      final roleManager = context.read<RoleManager>();

      if (roleManager.isLoading && !roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          isLoading: true,
          error: 'Verifying your role...',
        );
      }

      if (roleManager.error != null && !roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Error verifying role',
        );
      }

      if (!roleManager.isInitialized) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Role information unavailable',
        );
      }

      final currentRole = roleManager.currentRole;

      if (currentRole == null || currentRole == UserRole.unknown) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: currentRole,
          error: 'Role could not be determined',
        );
      }

      final hasAccess = allowedRoles.contains(currentRole);

      if (!hasAccess) {
        final allowedDisplay = allowedRoles
            .map((r) => r.displayName)
            .join(' or ');
        return RoleCheckResult(
          hasAccess: false,
          currentRole: currentRole,
          requiredRoles: allowedRoles,
          error: 'Access denied. This section requires: $allowedDisplay',
        );
      }

      return RoleCheckResult(
        hasAccess: true,
        currentRole: currentRole,
        requiredRoles: allowedRoles,
        isInitialized: true,
      );
    } catch (e) {
      debugPrint('[RoleCheck] Unexpected error in multiple role check: $e');
      return RoleCheckResult(
        hasAccess: false,
        currentRole: null,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Verify role from Firebase directly (useful for critical operations)
  static Future<RoleCheckResult> verifyRoleFromFirebase(
    String uid, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final instance = RoleCheckService();
      final docSnapshot = await instance._firebaseFirestore
          .collection('user_profile')
          .doc(uid)
          .get()
          .timeout(timeout);

      if (!docSnapshot.exists) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'User profile not found in database',
        );
      }

      final data = docSnapshot.data();
      if (data == null) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'User profile data is empty',
        );
      }

      final roleString = data['role'] as String?;
      if (roleString == null || roleString.trim().isEmpty) {
        return RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'Role information is missing',
        );
      }

      final role = UserRoleExtension.fromString(roleString);

      return RoleCheckResult(
        hasAccess: true,
        currentRole: role,
        isInitialized: true,
      );
    } on FirebaseException catch (e) {
      return RoleCheckResult(
        hasAccess: false,
        currentRole: null,
        error: 'Database error: ${e.message}',
      );
    } catch (e) {
      return RoleCheckResult(
        hasAccess: false,
        currentRole: null,
        error: 'Error verifying role: ${e.toString()}',
      );
    }
  }

  /// Check if user is authenticated
  static bool isUserAuthenticated(BuildContext context) {
    try {
      if (!context.mounted) return false;

      final roleManager = context.read<RoleManager>();
      return roleManager.isAuthenticated;
    } catch (e) {
      debugPrint('[RoleCheck] Error checking authentication: $e');
      return false;
    }
  }

  /// Get current role safely
  static UserRole? getCurrentRole(BuildContext context) {
    try {
      if (!context.mounted) return null;

      final roleManager = context.read<RoleManager>();
      if (!roleManager.isInitialized) return null;

      return roleManager.currentRole;
    } catch (e) {
      debugPrint('[RoleCheck] Error getting current role: $e');
      return null;
    }
  }

  /// Wait for role initialization with timeout
  static Future<bool> waitForRoleInitialization(
    BuildContext context, {
    Duration timeout = const Duration(seconds: 10),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      while (stopwatch.elapsed < timeout) {
        if (!context.mounted) return false;

        final roleManager = context.read<RoleManager>();
        if (roleManager.isInitialized) return true;

        await Future.delayed(checkInterval);
      }

      return false;
    } catch (e) {
      debugPrint('[RoleCheck] Error waiting for role init: $e');
      return false;
    }
  }

  /// Get role display name safely
  static String getRoleDisplayName(UserRole? role) {
    try {
      return role?.displayName ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Format error message for UI
  static String formatErrorMessage(String? error) {
    if (error == null || error.isEmpty) {
      return 'An error occurred. Please try again.';
    }
    return error;
  }
}

/// Extension on BuildContext for easy role checking
extension RoleCheckExtension on BuildContext {
  /// Check if user has specific role
  RoleCheckResult checkRole(UserRole role) {
    return RoleCheckService.checkUserRole(this, requiredRole: role);
  }

  /// Check if user has any of the roles
  RoleCheckResult checkRoleMultiple(List<UserRole> roles) {
    return RoleCheckService.checkUserRoleMultiple(this, allowedRoles: roles);
  }

  /// Get current role
  UserRole? getRole() {
    return RoleCheckService.getCurrentRole(this);
  }

  /// Check if authenticated
  bool isAuthenticated() {
    return RoleCheckService.isUserAuthenticated(this);
  }

  /// Wait for role initialization
  Future<bool> waitForRole({Duration? timeout}) {
    return RoleCheckService.waitForRoleInitialization(
      this,
      timeout: timeout ?? const Duration(seconds: 10),
    );
  }
}
