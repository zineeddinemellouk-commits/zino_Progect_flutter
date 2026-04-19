import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';

/// Result type for navigation operations
class NavigationResult {
  const NavigationResult({
    required this.success,
    this.error,
    this.errorType,
    this.returnedValue,
  });

  final bool success;
  final String? error;
  final NavigationErrorType? errorType;
  final dynamic returnedValue;

  @override
  String toString() => 'NavigationResult(success: $success, error: $error)';
}

/// Types of navigation errors
enum NavigationErrorType {
  roleNotVerified,
  unauthorized,
  navigationFailed,
  contextInvalid,
  asyncOperationFailed,
  timeoutError,
  unknown,
}

/// Safe navigation helper that wraps all navigation with error handling
/// Prevents app crashes and provides user feedback
class SafeNavigationHelper {
  /// Get the appropriate dashboard route for user's role
  /// Returns null if role is unknown or not initialized
  static String? getDashboardRouteForRole(UserRole? role) {
    try {
      switch (role) {
        case UserRole.student:
          return '/student-dashboard';
        case UserRole.teacher:
          return '/teacher-dashboard';
        case UserRole.department:
          return '/department-dashboard';
        case UserRole.unknown:
        case null:
          return null;
      }
    } catch (e) {
      debugPrint('[SafeNav] Error getting dashboard route: $e');
      return null;
    }
  }

  /// Safely navigate to a route with comprehensive error handling
  static Future<NavigationResult> safeNavigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Validate context
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context is not mounted. Cannot navigate.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      // Get role manager
      final roleManager = context.read<RoleManager>();

      // Check if role is initialized
      if (!roleManager.isInitialized) {
        return NavigationResult(
          success: false,
          error: 'User role not yet initialized. Please wait...',
          errorType: NavigationErrorType.roleNotVerified,
        );
      }

      // Try navigation with timeout
      final result = await Future.delayed(Duration.zero).then((_) {
        try {
          if (!context.mounted) {
            throw Exception('Context became unmounted');
          }

          // Perform navigation
          Navigator.of(context).pushNamed(routeName, arguments: arguments);
          return NavigationResult(success: true);
        } catch (e) {
          throw Exception('Navigation failed: ${e.toString()}');
        }
      }).timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Navigation timed out'),
      );

      return result;
    } on TimeoutException catch (e) {
      return NavigationResult(
        success: false,
        error: '${e.message}. Please try again.',
        errorType: NavigationErrorType.timeoutError,
      );
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Navigation error: ${e.toString()}',
        errorType: NavigationErrorType.navigationFailed,
      );
    }
  }

  /// Safely navigate with role verification
  /// Verifies user has the required role before navigating
  static Future<NavigationResult> safeNavigateToProtectedRoute(
    BuildContext context,
    String routeName,
    UserRole requiredRole, {
    List<UserRole>? allowedRoles,
    Object? arguments,
  }) async {
    try {
      // Validate context
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context is not mounted.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      // Get role manager
      final roleManager = context.read<RoleManager>();

      // Check if role is initialized
      if (!roleManager.isInitialized) {
        return NavigationResult(
          success: false,
          error: 'User role still loading. Please wait...',
          errorType: NavigationErrorType.roleNotVerified,
        );
      }

      // Check user's role
      final userRole = roleManager.currentRole;
      final actualAllowedRoles = allowedRoles ?? [requiredRole];

      if (userRole == null || userRole == UserRole.unknown) {
        return NavigationResult(
          success: false,
          error: 'Your role could not be verified. Please log in again.',
          errorType: NavigationErrorType.roleNotVerified,
        );
      }

      // Verify permission
      if (!actualAllowedRoles.contains(userRole)) {
        return NavigationResult(
          success: false,
          error:
              'Access denied. You are logged in as ${userRole.displayName}.\n'
              'Please use the ${userRole.displayName.toLowerCase()} interface.',
          errorType: NavigationErrorType.unauthorized,
        );
      }

      // Perform navigation
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context became unmounted during navigation.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      Navigator.of(context).pushNamed(routeName, arguments: arguments);

      return NavigationResult(
        success: true,
        returnedValue: userRole,
      );
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Navigation error: ${e.toString()}',
        errorType: NavigationErrorType.navigationFailed,
      );
    }
  }

  /// Safely navigate with replacement (pops current screen)
  static Future<NavigationResult> safeNavigateWithReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context is not mounted.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      Navigator.of(context).pushReplacementNamed(
        routeName,
        arguments: arguments,
      );

      return NavigationResult(success: true);
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Navigation error: ${e.toString()}',
        errorType: NavigationErrorType.navigationFailed,
      );
    }
  }

  /// Safely navigate with clear history
  static Future<NavigationResult> safeNavigateAndClearHistory(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context is not mounted.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        routeName,
        (route) => false,
        arguments: arguments,
      );

      return NavigationResult(success: true);
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Navigation error: ${e.toString()}',
        errorType: NavigationErrorType.navigationFailed,
      );
    }
  }

  /// Safely redirect to correct dashboard based on role
  /// Handles all error cases gracefully
  static Future<NavigationResult> safeRedirectToRoleDashboard(
    BuildContext context, {
    bool clearHistory = true,
  }) async {
    try {
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Cannot redirect - context not available.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      final roleManager = context.read<RoleManager>();

      // Wait for role initialization if needed
      if (!roleManager.isInitialized && roleManager.isLoading) {
        // Wait with timeout
        final stopwatch = Stopwatch()..start();
        const checkInterval = Duration(milliseconds: 100);
        const timeout = Duration(seconds: 10);

        while (!roleManager.isInitialized && stopwatch.elapsed < timeout) {
          await Future.delayed(checkInterval);
          if (!context.mounted) {
            return NavigationResult(
              success: false,
              error: 'Context lost while waiting for role.',
              errorType: NavigationErrorType.contextInvalid,
            );
          }
        }

        if (!roleManager.isInitialized) {
          return NavigationResult(
            success: false,
            error: 'Role initialization timed out.',
            errorType: NavigationErrorType.timeoutError,
          );
        }
      }

      // Get dashboard route
      final dashboardRoute = getDashboardRouteForRole(roleManager.currentRole);

      if (dashboardRoute == null) {
        return NavigationResult(
          success: false,
          error: 'Could not determine dashboard for role: '
              '${roleManager.currentRole?.displayName ?? "unknown"}',
          errorType: NavigationErrorType.roleNotVerified,
        );
      }

      // Navigate
      if (!context.mounted) {
        return NavigationResult(
          success: false,
          error: 'Context lost during navigation.',
          errorType: NavigationErrorType.contextInvalid,
        );
      }

      if (clearHistory) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          dashboardRoute,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamed(dashboardRoute);
      }

      return NavigationResult(
        success: true,
        returnedValue: dashboardRoute,
      );
    } catch (e) {
      return NavigationResult(
        success: false,
        error: 'Redirect failed: ${e.toString()}',
        errorType: NavigationErrorType.navigationFailed,
      );
    }
  }

  /// Log navigation attempt
  static void logNavigationAttempt(
    String routeName,
    NavigationResult result,
  ) {
    debugPrint(
      '[SafeNav] Route: $routeName | '
      'Success: ${result.success} | '
      'Error: ${result.error ?? "none"}',
    );
  }
}

/// Extension on BuildContext for easier safe navigation
extension SafeNavigation on BuildContext {
  /// Safely navigate to a protected route
  Future<NavigationResult> safeNavigateTo(
    String routeName, {
    Object? arguments,
  }) async {
    return SafeNavigationHelper.safeNavigateTo(
      this,
      routeName,
      arguments: arguments,
    );
  }

  /// Safely navigate to protected route with role check
  Future<NavigationResult> safeNavigateToProtected(
    String routeName,
    UserRole requiredRole, {
    List<UserRole>? allowedRoles,
    Object? arguments,
  }) async {
    return SafeNavigationHelper.safeNavigateToProtectedRoute(
      this,
      routeName,
      requiredRole,
      allowedRoles: allowedRoles,
      arguments: arguments,
    );
  }

  /// Safely redirect to dashboard
  Future<NavigationResult> safeRedirectToDashboard({
    bool clearHistory = true,
  }) async {
    return SafeNavigationHelper.safeRedirectToRoleDashboard(
      this,
      clearHistory: clearHistory,
    );
  }

  /// Get dashboard route for current user
  String? getMyDashboard() {
    try {
      final roleManager = read<RoleManager>();
      return SafeNavigationHelper.getDashboardRouteForRole(
        roleManager.currentRole,
      );
    } catch (e) {
      debugPrint('[SafeNav] Error getting dashboard: $e');
      return null;
    }
  }
}
