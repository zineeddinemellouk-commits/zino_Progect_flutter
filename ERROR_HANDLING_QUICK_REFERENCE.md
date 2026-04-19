# 🎯 Quick Reference: Error Handling & Safe Navigation

## 1-Minute Cheat Sheet

### Show Messages to User
```dart
context.showError('Error text');        // Red snackbar
context.showSuccess('Success text');    // Green snackbar  
context.showWarning('Warning text');    // Orange snackbar
context.showInfo('Info text');          // Blue snackbar
```

### Check Roles Safely
```dart
final result = context.checkRole(UserRole.student);
if (result.hasAccess) { /* show content */ }
else { context.showError(result.error); }
```

### Navigate Safely
```dart
final res = await context.safeNavigateTo('/route');
if (!res.success) context.showError(res.error);
```

### Protect a Screen
```dart
class MyScreen extends EnhancedRoleProtectedScreen {
  @override
  UserRole get requiredRole => UserRole.student;
  
  @override  
  Widget buildContent(BuildContext context) => YourContent();
}
```

---

## Pattern: Safe Button Press Handler

```dart
Future<void> _onButtonPress(BuildContext context) async {
  context.showInfo('Processing...');
  
  try {
    // Do async work
    await myAsyncOperation();
    
    if (context.mounted) {
      context.showSuccess('Done!');
    }
  } catch (e) {
    if (context.mounted) {
      context.showError(
        'Error: $e',
        onRetry: () => _onButtonPress(context),
      );
    }
  }
}
```

---

## Pattern: Tab Navigation with Role Checks

```dart
void _onTabChange(int index) async {
  // Check if user can access this tab
  final allowed = [UserRole.student, UserRole.teacher];
  final result = context.checkRoleMultiple(allowed);
  
  if (!result.hasAccess) {
    context.showError(result.error);
    return; // Don't switch tabs
  }
  
  // Access granted - toggle tab
  setState(() => _selectedTab = index);
}
```

---

## Pattern: Form with Error Handling

```dart
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  
  try {
    await submitToFirebase(_nameController.text);
    
    if (!context.mounted) return;
    
    _nameController.clear();
    context.showSuccess('Saved!');
    Navigator.pop(context);
    
  } catch (e) {
    if (!context.mounted) return;
    context.showError(
      'Failed to save',
      onRetry: _submitForm,
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

## Reference: All Available Methods

### Message Methods
```dart
context.showError(msg, onRetry: callback)          // Red snackbar
context.showSuccess(msg)                           // Green snackbar
context.showWarning(msg)                           // Orange snackbar  
context.showInfo(msg)                              // Blue snackbar

ErrorFeedbackHelper.showErrorSnackBar(context, msg)
ErrorFeedbackHelper.showAccessDeniedDialog(...)
ErrorFeedbackHelper.showLoadingDialog(...)
ErrorFeedbackHelper.showConfirmationDialog(...)
```

### Navigation Methods
```dart
context.safeNavigateTo('/route')                   // Safe navigate
context.safeNavigateToProtected('/r', role)        // With role check
context.safeRedirectToDashboard()                  // Route to correct dashboard
context.getMyDashboard()                           // Get my dashboard route
```

### Role Check Methods  
```dart
context.checkRole(UserRole.student)                // Check single
context.checkRoleMultiple([roles])                 // Check multiple
context.waitForRole(timeout: Duration(...))        // Wait for init
context.getRole()                                  // Get current role
context.isAuthenticated()                          // Is logged in
```

### Firebase Methods
```dart
await RoleCheckService.verifyRoleFromFirebase(uid)  // Direct verify
```

---

## Common Patterns

| Need | Code |
|------|------|
| **Check access before showing** | `if (ctx.checkRole(role).hasAccess) { show() }` |
| **Navigate with error** | `final r = await ctx.safeNavigateTo(r); if (!r.success) ctx.showError(r.error);` |
| **Show loading while init** | `if (!rm.isInitialized) return LoadingWidget();` |
| **Safe form submit** | See "Form" pattern above |
| **Button with retry** | `ctx.showError(msg, onRetry: _retry);` |
| **Access denied auto-redirect** | Use `EnhancedRoleProtectedScreen` - automatic |
| **Confirm before delete** | `await ctx.showConfirmationDialog(title, msg)` |
| **Verify from FB (critical)** | `await RoleCheckService.verifyRoleFromFirebase(uid)` |

---

## Imports Needed

```dart
import 'package:test/services/role_check_service.dart';      // For checkRole
import 'package:test/services/safe_navigation_helper.dart';  // For safe nav 
import 'package:test/utils/error_feedback_helper.dart';      // For dialogs
import 'package:test/widgets/enhanced_role_protected_screen.dart'; // Base widget
```

---

## What NOT To Do

| ❌ Don't | ✅ Instead |
|----------|-----------|
| `Navigator.pushNamed(ctx, r)` | `await ctx.safeNavigateTo(r)` |
| `role?.name ?? 'unknown'` | Use `result.currentRole?.displayName` |
| Bare `if (uid == x)` checks | Use `result.hasAccess` after role check |
| `showDialog(ctx, builder...)` | `ctx.showError()` or `ErrorFeedbackHelper.*` |
| Direct `ScaffoldMessenger.of` | `ctx.showSuccess/Error/Info/Warning` |
| No null checks before nav | Always check `if (context.mounted)` |
| Navigate during loading | Use result.success check first |

---

## Testing Checklist

- [ ] Try accessing wrong role section
- [ ] See: Error message + redirect to your dashboard (NO CRASH)
- [ ] Try clicking error "Retry" button
- [ ] See: Retry works without crash
- [ ] Force close app mid-navigation
- [ ] Reopen: No errors in logs
- [ ] Check role while Firestore is slow
- [ ] See: Loading spinner, then content or error
- [ ] All snackbars and dialogs appear correctly
- [ ] Confirm dialogs work before delete
- [ ] No "deactivated widget" errors in logs

---

## File Locations

| File | Purpose |
|------|---------|
| `lib/services/safe_navigation_helper.dart` | Safe nav + extensions |
| `lib/services/role_check_service.dart` | Role checking logic |
| `lib/utils/error_feedback_helper.dart` | Error UI components |
| `lib/widgets/enhanced_role_protected_screen.dart` | Safe base widget |
| `lib/pages/role_based_error_handling_example.dart` | Working examples |

