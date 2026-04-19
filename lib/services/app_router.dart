import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';

/// Centralized route guard system
/// Intercepts all navigation and enforces role-based access control
class AppRouter {
  AppRouter({required this.roleManager});

  final RoleManager roleManager;

  /// Define all protected routes and their required roles
  static const Map<String, List<UserRole>> protectedRoutes = {
    '/student-dashboard': [UserRole.student],
    '/student-attendance': [UserRole.student],
    '/student-absences': [UserRole.student],
    '/student-justifications': [UserRole.student],
    '/teacher-dashboard': [UserRole.teacher],
    '/teacher-attendance': [UserRole.teacher],
    '/teacher-profile': [UserRole.teacher],
    '/teacher-history': [UserRole.teacher],
    '/department-dashboard': [UserRole.department],
    '/department-users': [UserRole.department],
    '/department-settings': [UserRole.department],
    '/department-reports': [UserRole.department],
  };

  /// Check if a route requires authentication
  static bool isProtectedRoute(String routeName) {
    return protectedRoutes.containsKey(routeName);
  }

  /// Check if the current user can access a route
  bool canAccessRoute(String routeName) {
    // If route is not protected, allow access
    if (!isProtectedRoute(routeName)) {
      return true;
    }

    // If user is not authenticated, deny
    if (!roleManager.isAuthenticated) {
      return false;
    }

    // Check if user's role is allowed for this route
    final allowedRoles = protectedRoutes[routeName];
    if (allowedRoles == null) {
      return false;
    }

    return roleManager.hasAnyRole(allowedRoles);
  }

  /// Get the appropriate dashboard route for the current user
  String getDashboardRouteForCurrentRole() {
    switch (roleManager.currentRole) {
      case UserRole.student:
        return '/student-dashboard';
      case UserRole.teacher:
        return '/teacher-dashboard';
      case UserRole.department:
        return '/department-dashboard';
      case UserRole.unknown:
      case null:
        return '/login';
    }
  }

  /// Navigate to a route with role checks
  /// Returns true if navigation was allowed, false otherwise
  bool tryNavigate(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (!canAccessRoute(routeName)) {
      _showAccessDeniedDialog(context, routeName);
      return false;
    }

    Navigator.of(context).pushNamed(routeName, arguments: arguments);
    return true;
  }

  /// Navigate and replace with role checks
  bool tryNavigateReplacement(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (!canAccessRoute(routeName)) {
      _showAccessDeniedDialog(context, routeName);
      return false;
    }

    Navigator.of(context).pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
    return true;
  }

  /// Navigate and remove all previous routes
  bool tryNavigateAndClear(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    if (!canAccessRoute(routeName)) {
      _showAccessDeniedDialog(context, routeName);
      return false;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
    return true;
  }

  /// Show dialog when access is denied
  void _showAccessDeniedDialog(BuildContext context, String attemptedRoute) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('❌ Access Denied'),
        content: Text(
          'You do not have permission to access this screen.\n\n'
          'Your role: ${roleManager.currentRole?.displayName ?? 'Unknown'}\n'
          'Attempted route: $attemptedRoute',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to appropriate dashboard
              final dashboardRoute = getDashboardRouteForCurrentRole();
              Navigator.of(context).pushNamedAndRemoveUntil(
                dashboardRoute,
                (route) => false,
              );
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  /// Log all navigation attempts (for debugging)
  void logNavigationAttempt(String routeName, bool allowed) {
    debugPrint(
      '[ROUTE GUARD] Route: $routeName | '
      'Role: ${roleManager.currentRole?.value} | '
      'Allowed: $allowed',
    );
  }
}

/// Provides AppRouter to the widget tree
class AppRouterProvider {
  static AppRouter of(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    return AppRouter(roleManager: roleManager);
  }
}

/// Extension for easier navigation with guards
extension GuardedNavigation on BuildContext {
  AppRouter get appRouter {
    return AppRouter(roleManager: read<RoleManager>());
  }

  bool tryNavigate(String routeName, {Object? arguments}) {
    return appRouter.tryNavigate(this, routeName, arguments: arguments);
  }

  bool tryNavigateReplacement(String routeName, {Object? arguments}) {
    return appRouter.tryNavigateReplacement(
      this,
      routeName,
      arguments: arguments,
    );
  }

  bool tryNavigateAndClear(String routeName, {Object? arguments}) {
    return appRouter.tryNavigateAndClear(
      this,
      routeName,
      arguments: arguments,
    );
  }
}
