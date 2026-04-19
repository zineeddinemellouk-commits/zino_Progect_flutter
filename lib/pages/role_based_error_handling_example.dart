import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';
import 'package:test/services/role_check_service.dart';
import 'package:test/services/safe_navigation_helper.dart';
import 'package:test/utils/error_feedback_helper.dart';
import 'package:test/widgets/enhanced_role_protected_screen.dart';

/// Example page showing all error handling patterns working together
/// This demonstrates:
/// 1. Safe navigation with error handling
/// 2. Role checking with fallbacks
/// 3. User feedback via snackbars/dialogs
/// 4. Graceful error recovery
class RoleBasedErrorHandlingExample extends EnhancedRoleProtectedScreen {
  const RoleBasedErrorHandlingExample({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Examples'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role information card
            _RoleInformationCard(),

            const SizedBox(height: 24),
            const Text(
              'Error Handling Examples',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Example buttons
            _SafeNavigationExample(),
            const SizedBox(height: 12),
            _RoleCheckExample(),
            const SizedBox(height: 12),
            _ErrorFeedbackExample(),
            const SizedBox(height: 12),
            _RedirectExample(),
            const SizedBox(height: 12),
            _RoleVerificationExample(),
          ],
        ),
      ),
    );
  }
}

/// Card showing current user's role information
class _RoleInformationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RoleManager>(
      builder: (context, roleManager, _) {
        if (!roleManager.isInitialized) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        if (roleManager.error != null) {
          return Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Error',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(roleManager.error ?? 'Unknown error'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // Retry initialization
                      roleManager.initializeFromFirestore();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ));
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Profile',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Role:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          roleManager.currentRole?.displayName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Authenticated'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Example: Safe navigation with error handling
class _SafeNavigationExample extends StatelessWidget {
  const _SafeNavigationExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Safe Navigation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Navigate safely with error handling. If navigation fails, shows error message.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _demonstrateSafeNavigation(context),
              child: const Text('Try Safe Navigation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demonstrateSafeNavigation(BuildContext context) async {
    // Show loading
    ErrorFeedbackHelper.showInfoSnackBar(
      context,
      'Attempting to navigate...',
    );

    // Use safe navigation
    final result = await context.safeNavigateTo('/student-dashboard');

    if (!result.success && context.mounted) {
      ErrorFeedbackHelper.showErrorSnackBar(
        context,
        result.error ?? 'Navigation failed',
        onRetry: () => _demonstrateSafeNavigation(context),
      );
    }
  }
}

/// Example: Role checking with multiple fallbacks
class _RoleCheckExample extends StatelessWidget {
  const _RoleCheckExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. Role Checking',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check roles safely with comprehensive error handling and fallbacks.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _demonstrateRoleCheck(context),
              child: const Text('Check My Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _demonstrateRoleCheck(BuildContext context) {
    final result = context.checkRole(UserRole.student);

    debugPrint('[Example] Role check result: $result');

    if (result.hasAccess) {
      ErrorFeedbackHelper.showSuccessSnackBar(
        context,
        '✅ ${result.accessMessage}',
      );
    } else if (result.isLoading) {
      ErrorFeedbackHelper.showInfoSnackBar(
        context,
        '⏳ ${result.accessMessage}',
      );
    } else {
      ErrorFeedbackHelper.showErrorSnackBar(
        context,
        '❌ ${result.error ?? result.accessMessage}',
      );
    }
  }
}

/// Example: Error feedback UI
class _ErrorFeedbackExample extends StatelessWidget {
  const _ErrorFeedbackExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. Error Feedback UI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Examples of different error messages and dialogs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    ErrorFeedbackHelper.showErrorSnackBar(
                      context,
                      '❌ Error: This is a critical error message.',
                    );
                  },
                  child: const Text('Error'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    ErrorFeedbackHelper.showWarningSnackBar(
                      context,
                      '⚠️ Warning: Take care with this action.',
                    );
                  },
                  child: const Text('Warning'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    ErrorFeedbackHelper.showSuccessSnackBar(
                      context,
                      '✅ Success: Operation completed!',
                    );
                  },
                  child: const Text('Success'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    ErrorFeedbackHelper.showInfoSnackBar(
                      context,
                      'ℹ️ Info: This is useful information.',
                    );
                  },
                  child: const Text('Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Example: Redirect to dashboard
class _RedirectExample extends StatelessWidget {
  const _RedirectExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4. Smart Redirect',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically route to the correct dashboard based on role.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _demonstrateRedirect(context),
              child: const Text('Redirect to My Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demonstrateRedirect(BuildContext context) async {
    ErrorFeedbackHelper.showInfoSnackBar(
      context,
      'Redirecting...',
    );

    final result = await context.safeRedirectToDashboard();

    if (!result.success && context.mounted) {
      ErrorFeedbackHelper.showErrorSnackBar(
        context,
        result.error ?? 'Could not redirect',
      );
    }
  }
}

/// Example: Verify role from Firebase
class _RoleVerificationExample extends StatelessWidget {
  const _RoleVerificationExample();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '5. Firebase Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verify role directly from Firebase (useful for critical operations).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _demonstrateVerification(context),
              child: const Text('Verify from Firebase'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _demonstrateVerification(BuildContext context) async {
    ErrorFeedbackHelper.showLoadingDialog(
      context,
      message: 'Verifying role from Firebase...',
    );

    try {
      final roleManager = context.read<RoleManager>();
      if (roleManager.currentUserId == null) {
        if (context.mounted) Navigator.pop(context);
        ErrorFeedbackHelper.showErrorSnackBar(
          context,
          'User not authenticated',
        );
        return;
      }

      final result = await RoleCheckService.verifyRoleFromFirebase(
        roleManager.currentUserId!,
      );

      if (context.mounted) {
        Navigator.pop(context);

        if (result.hasAccess) {
          ErrorFeedbackHelper.showSuccessSnackBar(
            context,
            '✅ Verified: ${result.currentRole?.displayName}',
          );
        } else {
          ErrorFeedbackHelper.showErrorSnackBar(
            context,
            '❌ ${result.error}',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ErrorFeedbackHelper.showErrorSnackBar(
          context,
          'Verification failed: ${e.toString()}',
        );
      }
    }
  }
}
