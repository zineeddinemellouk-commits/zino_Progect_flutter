import 'package:flutter/material.dart';
import 'package:test/services/role_manager.dart';

/// Error feedback UI helper
/// Provides consistent, user-friendly error messages via SnackBar, Dialog, or pages
class ErrorFeedbackHelper {
  ErrorFeedbackHelper._();

  // Colors for different error types
  static const Color _errorColor = Color(0xFFB3261E); // Material Red
  static const Color _warningColor = Color(0xFFF57C00); // Material Orange
  static const Color _successColor = Color(0xFF00C853); // Material Green
  static const Color _infoColor = Color(0xFF0288D1); // Material Blue

  /// Show error snackbar with auto-dismiss
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    void Function()? onRetry,
  }) {
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: _errorColor,
            duration: duration,
            action: onRetry != null
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: Colors.white,
                    onPressed: onRetry,
                  )
                : null,
          ),
        );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing snackbar: $e');
    }
  }

  /// Show warning snackbar
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: _warningColor,
            duration: duration,
          ),
        );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing warning: $e');
    }
  }

  /// Show success snackbar
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: _successColor,
            duration: duration,
          ),
        );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing success: $e');
    }
  }

  /// Show info snackbar
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: _infoColor,
            duration: duration,
          ),
        );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing info: $e');
    }
  }

  /// Show access denied dialog
  static Future<void> showAccessDeniedDialog(
    BuildContext context, {
    String? userRole,
    required VoidCallback onGoToDashboard,
    VoidCallback? onDismiss,
  }) async {
    try {
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock, color: _errorColor),
              SizedBox(width: 8),
              Text('Access Denied'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You do not have permission to access this section.'),
              const SizedBox(height: 16),
              if (userRole != null) ...[
                Text(
                  'Current role: $userRole',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _warningColor,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'You will be redirected to your dashboard.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onDismiss?.call();
              },
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onGoToDashboard();
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing access denied dialog: $e');
    }
  }

  /// Show role mismatch error dialog
  static Future<void> showRoleMismatchDialog(
    BuildContext context, {
    required UserRole currentRole,
    required UserRole requiredRole,
    required VoidCallback onRetry,
  }) async {
    try {
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_remove, color: _errorColor),
              SizedBox(width: 8),
              Text('Role Mismatch'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This section is for ${requiredRole.displayName}s only.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your account: ${currentRole.displayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Required: ${requiredRole.displayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onRetry();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing role mismatch dialog: $e');
    }
  }

  /// Show role loading dialog
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String message = 'Verifying your permissions...',
  }) async {
    try {
      if (!context.mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing loading dialog: $e');
    }
  }

  /// Dismiss any open dialog
  static void dismissDialog(BuildContext context) {
    try {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[ErrorFeedback] Error dismissing dialog: $e');
    }
  }

  /// Show auth error dialog with specific message
  static Future<void> showAuthErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Authentication Error',
    required VoidCallback onRetry,
  }) async {
    try {
      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.security, color: _errorColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing auth dialog: $e');
    }
  }

  /// Show generic error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String message,
    String title = 'Error',
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    try {
      if (!context.mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: _errorColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                child: Text(actionLabel),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing error dialog: $e');
    }
  }

  /// Show confirmation dialog for critical operations
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    try {
      if (!context.mounted) return false;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );

      return result ?? false;
    } catch (e) {
      debugPrint('[ErrorFeedback] Error showing confirmation dialog: $e');
      return false;
    }
  }
}

/// Extension on BuildContext for easier error feedback
extension ErrorFeedback on BuildContext {
  /// Show error snackbar
  void showError(String message, {void Function()? onRetry}) {
    ErrorFeedbackHelper.showErrorSnackBar(
      this,
      message,
      onRetry: onRetry,
    );
  }

  /// Show success message
  void showSuccess(String message) {
    ErrorFeedbackHelper.showSuccessSnackBar(this, message);
  }

  /// Show warning message
  void showWarning(String message) {
    ErrorFeedbackHelper.showWarningSnackBar(this, message);
  }

  /// Show info message
  void showInfo(String message) {
    ErrorFeedbackHelper.showInfoSnackBar(this, message);
  }

  /// Show access denied dialog
  Future<void> showAccessDenied({
    String? userRole,
    required VoidCallback onGoToDashboard,
  }) {
    return ErrorFeedbackHelper.showAccessDeniedDialog(
      this,
      userRole: userRole,
      onGoToDashboard: onGoToDashboard,
    );
  }
}
