import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';

/// A base widget that enforces role-based access control
/// 
/// Usage:
/// ```dart
/// class StudentDashboard extends RoleProtectedScreen {
///   StudentDashboard({super.key});
/// 
///   @override
///   UserRole get requiredRole => UserRole.student;
/// 
///   @override
///   Widget buildContent(BuildContext context) {
///     return YourStudentContent();
///   }
/// }
/// ```
abstract class RoleProtectedScreen extends StatelessWidget {
  const RoleProtectedScreen({super.key});

  /// Override this to specify which role(s) can access this screen
  UserRole get requiredRole;

  /// Override this to specify multiple allowed roles (if applicable)
  List<UserRole>? get allowedRoles => null;

  /// Build the protected content - only shown if role matches
  Widget buildContent(BuildContext context);

  /// Called when user tries to access but doesn't have permission
  /// Override to customize the error page
  Widget buildAccessDeniedPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Access Denied',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'You do not have permission to access this screen.\nYour role: ${context.read<RoleManager>().currentRole?.displayName ?? 'Unknown'}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _navigateToDashboard(context);
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  /// Called when role is still loading
  Widget buildLoadingPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Called when there's an error loading the role
  Widget buildErrorPage(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Role',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to the appropriate dashboard based on role
  void _navigateToDashboard(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    
    if (context.mounted) {
      final route = _getRouteForRole(roleManager.currentRole);
      if (route != null) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          route,
          (route) => false,
        );
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  /// Get the dashboard route for a given role
  String? _getRouteForRole(UserRole? role) {
    switch (role) {
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

  /// Check if the user has the required role
  bool _userHasRequiredRole(RoleManager roleManager) {
    final allowedRolesList = allowedRoles;
    
    if (allowedRolesList != null && allowedRolesList.isNotEmpty) {
      return roleManager.hasAnyRole(allowedRolesList);
    }
    
    return roleManager.hasRole(requiredRole);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        // Check if role manager is still loading
        if (!roleManager.isInitialized && roleManager.isLoading) {
          return buildLoadingPage(context);
        }

        // Check if there's an error
        if (roleManager.error != null && !roleManager.isInitialized) {
          return buildErrorPage(context, roleManager.error ?? 'Unknown error');
        }

        // Check if user is authenticated
        if (!roleManager.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          });
          return buildLoadingPage(context);
        }

        // Check if user has the required role
        if (!_userHasRequiredRole(roleManager)) {
          return buildAccessDeniedPage(context);
        }

        // User is authenticated and has the required role - show content
        return buildContent(context);
      },
    );
  }
}

/// Helper widget for role-based condition rendering
class RoleConditional extends StatelessWidget {
  const RoleConditional({
    required this.requiredRole,
    required this.child,
    this.fallback,
    super.key,
  });

  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        if (!roleManager.hasRole(requiredRole)) {
          return fallback ?? const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}

/// Helper widget to conditionally show based on multiple roles
class MultiRoleConditional extends StatelessWidget {
  const MultiRoleConditional({
    required this.allowedRoles,
    required this.child,
    this.fallback,
    super.key,
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        if (!roleManager.hasAnyRole(allowedRoles)) {
          return fallback ?? const SizedBox.shrink();
        }
        return child;
      },
    );
  }
}
