# 🚀 Quick Reference - Role-Based Access Control

## Files Created/Modified

```
✅ lib/services/role_manager.dart          - Central role management
✅ lib/services/auth_service.dart          - Secure auth flow  
✅ lib/services/user_repository.dart       - Role-specific data access
✅ lib/services/app_router.dart            - Route guards
✅ lib/widgets/role_protected_screen.dart  - Protected screen base
✅ lib/pages/protected_dashboards.dart     - Example dashboards
✅ lib/main_secure.dart                    - Secure main.dart pattern
✅ firestore.rules                         - Security rules
✅ ROLE_BASED_ACCESS_CONTROL_GUIDE.md     - Full documentation
✅ MIGRATION_TO_ROLE_BASED_SECURITY.md    - Migration guide
```

---

## Core Concepts

### UserRole Enum
```dart
enum UserRole { student, teacher, department, unknown }
```

### RoleManager (Global State)
```dart
// Get current user's role
Context.read<RoleManager>().currentRole
Context.read<RoleManager>().currentUserId  
Context.read<RoleManager>().currentUserEmail

// Check role
Context.read<RoleManager>().isStudent
Context.read<RoleManager>().isTeacher
Context.read<RoleManager>().isDepartment
```

### RoleProtectedScreen (Base Widget)
```dart
class MyScreen extends RoleProtectedScreen {
  UserRole get requiredRole => UserRole.student;
  
  Widget buildContent(BuildContext context) {
    return Scaffold(...);
  }
}
```

---

## 5-Minute Setup

### 1. Update pubspec.yaml (if needed)
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  provider: ^latest
```

### 2. Replace main.dart
Copy pattern from `lib/main_secure.dart`

### 3. Deploy Firestore Rules
Copy rules from `firestore.rules` to Firebase Console

### 4. Create your protected screens
```dart
class MyScreen extends RoleProtectedScreen {
  UserRole get requiredRole => UserRole.student;
  Widget buildContent(BuildContext context) => Scaffold(...);
}
```

### 5. Update routes in main.dart
```dart
routes: {
  '/login': (_) => const LoginPage(),
  '/student-dashboard': (_) => const StudentDashboard(),
  '/teacher-dashboard': (_) => const TeacherDashboard(),
  '/department-dashboard': (_) => const DepartmentDashboard(),
}
```

---

## Common Code Snippets

### Get Current User Info
```dart
final role = context.read<RoleManager>().currentRole;
final userId = context.read<RoleManager>().currentUserId;
final email = context.read<RoleManager>().currentUserEmail;
```

### Check Role
```dart
if (context.read<RoleManager>().isStudent) {
  // Show student content
}
```

### Show/Hide Based on Role
```dart
RoleConditional(
  requiredRole: UserRole.teacher,
  child: ElevatedButton(
    onPressed: () => recordAttendance(),
    child: Text('Record Attendance'),
  ),
)
```

### Navigate Safely (with guard)
```dart
context.tryNavigate('/student-dashboard'); // Returns bool
```

### Manual Role Check
```dart
bool hasAccess = router.canAccessRoute('/teacher-dashboard');
```

### Logout
```dart
await context.read<AuthService>().logout(
  roleManager: context.read<RoleManager>(),
);
```

### Verify User Role
```dart
bool isTeacher = await authService.verifyUserRole('teacher');
```

---

## Database Schema

```
user_profile/                      ← ROLE STORED HERE
├── {uid}/
│   ├── role: "student|teacher|department"
│   ├── email: "user@example.com"
│   ├── displayName: "John"
│   └── timestamps

student/
├── {uid}/                         ← Matches user_profile {uid}
│   ├── name, level, group, etc.

teacher/
├── {uid}/                         ← Matches user_profile {uid}
│   ├── name, subject, levels, etc.

department/
├── {uid}/                         ← Matches user_profile {uid}
│   ├── name, position, etc.
```

**CRITICAL:** Role is ONLY in `user_profile`. Never store role in other collections.

---

## Firestore Rules Summary

| Collection | Student | Teacher | Department |
|-----------|---------|---------|-----------|
| user_profile | Own only | Own only | Own only |
| student | Own | All | All |
| teacher | ❌ | Own | All |
| department | ❌ | ❌ | Own |
| absences | Own | Manage | Manage |
| notifications | Own | - | Manage |

**Key:** ❌ = Blocked, Own = Own doc only, All = All docs, Manage = Create/Update

---

## Security Layers

### Layer 1: Client-Side (RoleProtectedScreen)
```dart
✅ Fast check before rendering
✅ Prevents UI from appearing
❌ Can be bypassed
```

### Layer 2: Client-Side (AppRouter)
```dart
✅ Prevents navigation attempts
✅ Catches accidental attempts to navigate wrong route
❌ Can be bypassed (never trust client)
```

### Layer 3: Server-Side (Firestore Rules)
```dart
✅ Final security checkpoint
✅ No way to bypass
✅ Prevents data access even if app is compromised
```

---

## Testing Checklist

```
□ Login as student
  ├─ Verify StudentDashboard shows
  ├─ Try accessing /teacher-dashboard → Access Denied
  └─ Student data loads in Firestore

□ Login as teacher  
  ├─ Verify TeacherDashboard shows
  ├─ Try accessing /student-dashboard → Access Denied
  └─ Can see all student attendance

□ Login as department
  ├─ Verify DepartmentDashboard shows
  ├─ Can access all sections
  └─ Can see all user data

□ Firestore Rules
  ├─ Student queries student/{uid} → Success
  ├─ Student queries teacher/{uid} → Blocked
  ├─ Teacher queries absences where studentId → Success
  └─ Audit log creation → All roles can create
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Access Denied" on login | Check `user_profile` exists with valid `role` |
| Black screen after login | Ensure `RoleManager.initializeFromFirestore()` called |
| Can still access wrong role's screen | Rebuild app with new security code |
| Firestore queries fail with permission | Deploy rules and check user role in Firebase Console |
| Role shows "unknown" | Make sure `user_profile` role field is set |

---

## Deployment Checklist

```
PRE-DEPLOYMENT:

□ All screens extend RoleProtectedScreen
□ RoleManager integrated in main.dart
□ AuthService used for all authentication
□ Firestore rules deployed and tested
□ All routes defined in main.dart
□ userId not passed as constructor param
□ No hardcoded test UIDs in code
□ role obtained from RoleManager only
□ All tests passing with role security
□ Firestore indexes built for queries
□ Security rules tested with different roles

DEPLOYMENT:

□ Deploy to staging environment
□ Test logins with all roles
□ Test navigation between screens
□ Test Firestore access from different roles
□ Review authentication logs
□ Monitor for failed access attempts
□ Get security team sign-off

PRODUCTION:

□ Deploy rules gradually (if testing new collections)
□ Monitor access violations
□ Set up alerts for unusual login patterns
□ Teach users about role restrictions
□ Document role-specific features
```

---

## Key Files Reference

### role_manager.dart
**Purpose:** Central role state management
**Key Methods:**
- `initializeFromFirestore()` - Fetch & set role
- `hasRole(role)` - Check if has role
- `hasAnyRole([roles])` - Check if has any of roles

### auth_service.dart
**Purpose:** Secure authentication
**Key Methods:**
- `login(email, pwd, roleManager)` - Authenticate user
- `logout(roleManager)` - Sign out & clear role
- `getUserRole(uid)` - Get role from Firestore
- `verifyUserRole(role)` - Verify current user's role

### role_protected_screen.dart
**Purpose:** Protect screens by role
**Key Methods:**
- `requiredRole` - Override with required role
- `buildContent()` - Override with screen UI
- `buildAccessDeniedPage()` - Override for custom denied UI

### app_router.dart
**Purpose:** Guard routes by role
**Key Methods:**
- `canAccessRoute(name)` - Check if allowed
- `tryNavigate()` - Navigate with guard
- `tryNavigateReplacement()` - Replace with guard
- `tryNavigateAndClear()` - Clear stack with guard

---

## Examples

### Example 1: Protected Student Screen
```dart
class StudentAbsencesPage extends RoleProtectedScreen {
  const StudentAbsencesPage({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    final userId = context.read<RoleManager>().currentUserId!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Absences')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('absences')
            .where('studentId', isEqualTo: userId)
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.docs.map((doc) {
                return ListTile(title: Text(doc['subject']));
              }).toList(),
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
```

### Example 2: Check Role and Show Button
```dart
RoleConditional(
  requiredRole: UserRole.teacher,
  child: FloatingActionButton(
    onPressed: () => recordAttendance(),
    child: const Icon(Icons.add),
  ),
  fallback: const SizedBox.shrink(),
)
```

### Example 3: Message Based on Role
```dart
Text(
  'You are logged in as: '
  '${context.read<RoleManager>().currentRole?.displayName}',
)
```

---

## Performance Tips

1. **Cache RoleManager** - Use `context.read<RoleManager>()` not `Provider.of`
2. **Use StreamBuilder** - For real-time data with Firestore
3. **Index Queries** - Add Firestore indexes for complex queries
4. **Lazy Load** - Only load data when screen is built
5. **Keep Rules Simple** - Easier rules load faster

---

## Security Best Practices

```
✅ DO:
  - Store role ONLY in user_profile
  - Verify role on every login
  - Use RoleProtectedScreen for all role-specific screens
  - Check role before accessing sensitive data
  - Deploy Firestore rules immediately
  - Test with different role users
  - Use HTTPS for all API calls
  - Rotate auth tokens regularly

❌ DON'T:
  - Store role in local storage
  - Trust client-side role checks alone
  - Pass role as constructor parameter
  - Hardcode role values
  - Skip Firestore rule deployment
  - Use same account for different roles
  - Share auth tokens
  - Disable security rules on production
```

---

## Support Resources

- Full Guide: `ROLE_BASED_ACCESS_CONTROL_GUIDE.md`
- Migration: `MIGRATION_TO_ROLE_BASED_SECURITY.md`
- Example Screens: `lib/pages/protected_dashboards.dart`
- Security Rules: `firestore.rules`

---

**You're all set! Start with the full guide, then refer back to this card for quick lookups. 🚀**
