import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';
import 'package:test/services/role_check_service.dart';
import 'package:test/services/safe_navigation_helper.dart';
import 'package:test/utils/error_feedback_helper.dart';

/// Enhanced version of RoleProtectedScreen with improved error handling
/// This version automatically handles loading states, errors, and redirects
///
/// Usage:
/// ```dart
/// class StudentDashboard extends EnhancedRoleProtectedScreen {
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
abstract class EnhancedRoleProtectedScreen extends StatefulWidget {
  const EnhancedRoleProtectedScreen({super.key});

  /// Override this to specify which role(s) can access this screen
  UserRole get requiredRole;

  /// Override this to specify multiple allowed roles
  List<UserRole>? get allowedRoles => null;

  /// Build the protected content - only shown if role matches
  /// This is called AFTER all role verification passes
  Widget buildContent(BuildContext context);

  /// Override to show custom loading UI
  Widget buildLoadingPage(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Verifying your access...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Override to show custom error UI
  Widget buildErrorPage(BuildContext context, String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Unable to Load',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () {
                // Trigger rebuild
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Override to show custom access denied UI
  Widget buildAccessDeniedPage(BuildContext context) {
    final roleManager = context.read<RoleManager>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 64,
                  color: Color(0xFFB3261E),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You do not have permission to access this section.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Account:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        roleManager.currentRole?.displayName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This section requires:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        requiredRole.displayName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Go to Your Dashboard'),
                      onPressed: () => _handleAccessDenied(context),
                    ),
                    if (!roleManager.isAuthenticated) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle access denied - redirect to dashboard
  Future<void> _handleAccessDenied(BuildContext context) async {
    final result = await context.safeRedirectToDashboard();

    if (!result.success && context.mounted) {
      ErrorFeedbackHelper.showErrorSnackBar(
        context,
        result.error ?? 'Could not redirect to dashboard',
      );
    }
  }

  @override
  State<EnhancedRoleProtectedScreen> createState() =>
      _EnhancedRoleProtectedScreenState();
}

class _EnhancedRoleProtectedScreenState
    extends State<EnhancedRoleProtectedScreen> {
  late RoleCheckResult _roleCheckResult;
  bool _isInitialized = false;
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _performRoleCheck();
  }

  /// Perform role check with error handling
  void _performRoleCheck() {
    try {
      final roleManager = context.read<RoleManager>();

      // Handle not initialized
      if (!roleManager.isInitialized && roleManager.isLoading) {
        setState(() {
          _roleCheckResult = RoleCheckResult(
            hasAccess: false,
            currentRole: null,
            isLoading: true,
            error: 'Verifying your role...',
          );
        });
        return;
      }

      // Handle error during initialization
      if (roleManager.error != null && !roleManager.isInitialized) {
        setState(() {
          _roleCheckResult = RoleCheckResult(
            hasAccess: false,
            currentRole: null,
            error: roleManager.error ?? 'Failed to verify role',
          );
          _isInitialized = true;
        });
        return;
      }

      // Get role check result
      final allowedRoles = widget.allowedRoles ?? [widget.requiredRole];
      _roleCheckResult = RoleCheckService.checkUserRoleMultiple(
        context,
        allowedRoles: allowedRoles,
      );

      setState(() {
        _isInitialized = true;
      });

      // Show error message if access denied and not already shown
      if (!_roleCheckResult.hasAccess &&
          !_hasShownError &&
          _roleCheckResult.error != null) {
        _hasShownError = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ErrorFeedbackHelper.showWarningSnackBar(
              context,
              _roleCheckResult.error!,
              duration: const Duration(seconds: 2),
            );

            // Auto-redirect after brief delay
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                widget._handleAccessDenied(context);
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[EnhancedRoleProtected] Error during role check: $e');
      setState(() {
        _roleCheckResult = RoleCheckResult(
          hasAccess: false,
          currentRole: null,
          error: 'An unexpected error occurred. Please try again.',
        );
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        // Show loading page if still initializing
        if (!_isInitialized || (roleManager.isLoading && !roleManager.isInitialized)) {
          return widget.buildLoadingPage(context);
        }

        // Show error page if there was an error
        if (!_roleCheckResult.hasAccess && _roleCheckResult.error != null) {
          // For auth errors, show error page
          if (!roleManager.isAuthenticated) {
            return widget.buildErrorPage(
              context,
              'You are not authenticated. Please log in.',
            );
          }

          // For access denied, show access denied page
          return widget.buildAccessDeniedPage(context);
        }

        // Check if user has permission
        if (!_roleCheckResult.hasAccess) {
          return widget.buildAccessDeniedPage(context);
        }

        // User has access - show content
        try {
          return widget.buildContent(context);
        } catch (e) {
          debugPrint('[EnhancedRoleProtected] Error building content: $e');
          return widget.buildErrorPage(
            context,
            'Error loading this page. Please try again.',
          );
        }
      },
    );
  }
}

/// Helper widget for showing content based on role
class RoleBasedBuilder extends StatelessWidget {
  const RoleBasedBuilder({
    required this.requiredRole,
    required this.builder,
    this.fallback,
    super.key,
  });

  final UserRole requiredRole;
  final WidgetBuilder builder;
  final WidgetBuilder? fallback;

  @override
  Widget build(BuildContext context) {
    try {
      final roleCheck = RoleCheckService.checkUserRole(
        context,
        requiredRole: requiredRole,
      );

      if (roleCheck.hasAccess) {
        return builder(context);
      }

      if (fallback != null) {
        return fallback!(context);
      }

      return SizedBox.shrink();
    } catch (e) {
      debugPrint('[RoleBasedBuilder] Error: $e');
      return fallback?.call(context) ?? const SizedBox.shrink();
    }
  }
}

/// Helper widget for multiple roles
class MultiRoleBasedBuilder extends StatelessWidget {
  const MultiRoleBasedBuilder({
    required this.allowedRoles,
    required this.builder,
    this.fallback,
    super.key,
  });

  final List<UserRole> allowedRoles;
  final WidgetBuilder builder;
  final WidgetBuilder? fallback;

  @override
  Widget build(BuildContext context) {
    try {
      final roleCheck = RoleCheckService.checkUserRoleMultiple(
        context,
        allowedRoles: allowedRoles,
      );

      if (roleCheck.hasAccess) {
        return builder(context);
      }

      if (fallback != null) {
        return fallback!(context);
      }

      return const SizedBox.shrink();
    } catch (e) {
      debugPrint('[MultiRoleBasedBuilder] Error: $e');
      return fallback?.call(context) ?? const SizedBox.shrink();
    }
  }
}
