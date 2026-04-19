# ✅ Step-by-Step Implementation Checklist

## Phase 1: Setup Services (30 minutes)

### Step 1.1: Create Core Services ✓

- [x] `lib/services/role_manager.dart` - Created with RoleManager class
- [x] `lib/services/auth_service.dart` - Created with AuthService class
- [x] `lib/services/user_repository.dart` - Created with UserRepository class
- [x] `lib/services/app_router.dart` - Created with AppRouter class

**Verification:**
```bash
flutter analyze lib/services/
# Should show 0 errors
```

### Step 1.2: Create UI Components ✓

- [x] `lib/widgets/role_protected_screen.dart` - Created base widget
- [x] `lib/pages/protected_dashboards.dart` - Created example dashboards

**Verification:**
```bash
flutter get
flutter analyze lib/widgets/
flutter analyze lib/pages/protected_dashboards.dart
```

### Step 1.3: Create Updated Main ✓

- [x] `lib/main_secure.dart` - Created with proper provider setup

**Verification:**
```bash
# Compare with existing main.dart
# Don't replace yet - we'll do that in Phase 2
```

---

## Phase 2: Update Your App (1-2 hours)

### Step 2.1: Update main.dart

**Current Status:** Your existing main.dart still runs the old way

**TODO:**
- [ ] Compare `lib/main_secure.dart` with your current `lib/main.dart`
- [ ] Note the differences:
  - [ ] MultiProvider setup with RoleManager and AuthService
  - [ ] _AuthGate widget for stream-based routing
  - [ ] Named routes configuration
- [ ] Backup your current main.dart
  ```bash
  cp lib/main.dart lib/main_backup.dart
  ```
- [ ] Option A: Directly update `lib/main.dart` using the pattern from `main_secure.dart`
- [ ] Option B: Keep both and switch named entry point

**Verification:**
```bash
flutter pub get
flutter analyze lib/main.dart
# Should compile without errors
```

### Step 2.2: Update Your Login Page

**Current Status:** `lib/pages/login_page.dart` uses old flow

**TODO:**
- [ ] Open `lib/pages/login_page.dart`
- [ ] In `handleLogin()` method, update:

```dart
// OLD WAY
Future<void> handleLogin() async {
  final profile = await authService.signInWithRole(
    email: email,
    password: password,
    expectedRole: selectedRole,
  );
  // Navigate somewhere
}

// NEW WAY  
Future<void> handleLogin() async {
  final authService = context.read<AuthService>();
  final roleManager = context.read<RoleManager>();
  
  await authService.login(
    email: email,
    password: password,
    roleManager: roleManager,
  );
  // Navigation happens automatically via _AuthGate
  // Just show success message
}
```

- [ ] Wrap error handling properly
- [ ] Test login with each role

**Verification:**
```bash
flutter test lib/pages/login_page.dart
# Or run app and test login
```

### Step 2.3: Update Firestore Rules

**Current Status:** Rules are not enforcing role-based access

**TODO:**
- [ ] Go to Firebase Console → Your Project → Firestore Database
- [ ] Click on "Rules" tab
- [ ] Copy the entire content of `firestore.rules` file
- [ ] Paste into Firebase Console rules editor
- [ ] Click "Publish"
  
**⚠️ WARNING:** This will enforce rules immediately. Make sure:
- [ ] All existing user_profile documents have a valid `role` field
- [ ] TestMode rules are NOT in use on production
- [ ] Your app uses the new AuthService (which creates user_profile)

**Verification:**
```bash
# From app, try to:
1. Login as student
2. Query Firestore as student
   - Should succeed for own data
   - Should fail for teacher/department data
```

---

## Phase 3: Migrate Existing Screens (2-4 hours)

### Step 3.1: Identify All Role-Specific Screens

**TODO:**
Create a list of all screens that should be role-restricted:

```
STUDENT SCREENS:
□ StudentsPage (student dashboard)
□ AbsenceTrackerPage
□ JustificationPage
□ NotificationsPage
□ Your custom screens...

TEACHER SCREENS:
□ TeacherProfilePage
□ TeacherAttendanceGroupsPage
□ AttendanceRecordingPage
□ Your custom screens...

DEPARTMENT SCREENS:
□ DepartmentDashboard
□ ViewTeachers
□ ViewStudents
□ Department settings
□ Your custom screens...

SHARED SCREENS (multiple roles):
□ AttendancePage (student + teacher)
□ ReportsPage (teacher + department)
□ Your custom screens...
```

### Step 3.2: Convert Screens One-by-One

For each screen above:

```
TEMPLATE:

Class Name: ________________
Current Role: ________________
Required Roles: ________________

STEPS:
□ Change from StatefulWidget/StatelessWidget to RoleProtectedScreen
□ Add: @override UserRole get requiredRole => UserRole.student;
□ Add: @override Widget buildContent(BuildContext context) { ... }
□ Move all build() logic into buildContent()
□ Remove constructor parameters for userId/role/email
□ Replace with: context.read<RoleManager>().currentUserId
□ Test with different roles
□ Commit changes
```

### Step 3.3: Example Conversion

**Before:**
```dart
class StudentsPage extends StatefulWidget {
  const StudentsPage({
    required this.selfViewOnly,
    required this.studentDocumentId,
    required this.studentEmail,
  });
  // ...
}
```

**After:**
```dart
class StudentsPage extends RoleProtectedScreen {
  const StudentsPage({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    final userId = context.read<RoleManager>().currentUserId!;
    // Use userId instead of widget.studentDocumentId
    // ...
  }
}
```

---

## Phase 4: Testing (1-2 hours)

### Step 4.1: Unit Tests for RoleManager

```bash
# Create: test/services/role_manager_test.dart

□ Test RoleManager can initialize from Firestore
□ Test hasRole() method
□ Test hasAnyRole() method  
□ Test role clearing on logout
□ Test error handling for missing user_profile
```

### Step 4.2: Integration Tests for Protected Screens

```bash
# Create: test_driver/app_test.dart

□ Test student can access StudentDashboard
□ Test teacher cannot access StudentDashboard
□ Test teacher can access TeacherDashboard
□ Test student cannot access DepartmentDashboard
□ Test login routes to correct dashboard
□ Test logout clears role
```

### Step 4.3: Manual Testing

For EACH role combination:

**Testing as STUDENT:**
- [ ] Login with student account
  - [ ] Verify StudentDashboard shown
  - [ ] Check role in UI shows "Student"
- [ ] Try navigating to teacher page (manually in terminal)
  - [ ] Should see "Access Denied"
- [ ] Try navigating to department page
  - [ ] Should see "Access Denied"
- [ ] Logout
  - [ ] Back to login
- [ ] Login again
  - [ ] Role loads correctly

**Testing as TEACHER:**
- [ ] Login with teacher account
  - [ ] Verify TeacherDashboard shown
  - [ ] Check role in UI shows "Teacher"
- [ ] Try navigating to student page
  - [ ] Should see "Access Denied"
- [ ] Try navigating to department page
  - [ ] Should see "Access Denied"
- [ ] Try accessing Firestore from student collection
  - [ ] Should fail with permission error

**Testing as DEPARTMENT:**
- [ ] Login with department account
  - [ ] Verify DepartmentDashboard shown
  - [ ] Check role in UI shows "Department"
- [ ] Navigate to all screens
  - [ ] All accessible
- [ ] Check all data viewable
  - [ ] Can see all students/teachers/data

### Step 4.4: Firestore Rules Testing

```bash
# Test each collection access:

□ user_profile
  ├─ User can read own: ✓
  ├─ User cannot read other's: block
  └─ User cannot modify role field: block

□ student
  ├─ Student reads own: ✓
  ├─ Student reads other: block
  ├─ Teacher reads all: ✓
  └─ Department reads all: ✓

□ teacher
  ├─ Teacher reads own: ✓
  ├─ Teacher reads other: block
  ├─ Student reads any: block
  └─ Department reads all: ✓

□ absences
  ├─ Student queries own: ✓
  ├─ Teacher queries all: ✓
  └─ Department queries all: ✓
```

---

## Phase 5: Documentation & Cleanup (30 minutes)

### Step 5.1: Update README.md

Add section about security:

```markdown
## Security

This app uses role-based access control:

- **Student**: Can access only student features
- **Teacher**: Can access only teacher features  
- **Department**: Can access all admin features

See [ROLE_BASED_ACCESS_CONTROL_GUIDE.md](ROLE_BASED_ACCESS_CONTROL_GUIDE.md) for details.
```

### Step 5.2: Document Your Screens

Create a file `SCREENS_AND_ROLES.md`:

```markdown
## Screen Access Matrix

| Screen | Student | Teacher | Department |
|--------|---------|---------|-----------|
| StudentDashboard | ✓ | ✗ | ✓ |
| TeacherDashboard | ✗ | ✓ |  ✓ |
| DepartmentDashboard | ✗ | ✗ | ✓ |
| AttendancePage | ✓ | ✓ | ✓ |
| ...etc |
```

### Step 5.3: Cleanup

- [ ] Remove old auth code that's not used
- [ ] Remove test/debug screens
- [ ] Remove unused imports
- [ ] Delete backup files when confident
- [ ] Remove old DepartmentAuthService if replaced

---

## Phase 6: Deployment (1 hour)

### Step 6.1: Pre-Deployment

- [ ] All tests passing
  ```bash
  flutter test
  ```
- [ ] No lint warnings
  ```bash
  flutter analyze
  ```
- [ ] App runs without errors
  ```bash
  flutter run --release
  ```
- [ ] Firestore rules deployed
- [ ] Authentication working with all roles
- [ ] All screens tested with appropriate roles

### Step 6.2: Staging Deployment

- [ ] Build staging APK/IPA
  ```bash
  flutter build apk --release -t lib/main.dart
  flutter build ios --release -t lib/main.dart
  ```
- [ ] Test on physical devices with different roles
- [ ] Monitor logs for errors
- [ ] Get team approval

### Step 6.3: Production Deployment

- [ ] Backup current Firestore rules
- [ ] Publish new rules gradually if adding features
- [ ] Deploy app update
- [ ] Monitor auth logs for issues
- [ ] Be ready to rollback rules if needed

### Step 6.4: Post-Deployment

- [ ] Monitor for access violations
- [ ] Check error logs for rule violations
- [ ] Follow up with users if help needed
- [ ] Document any issues found

---

## Verification Checklist

Use this before marking implementation complete:

### Functional ✓
- [ ] Student login works
- [ ] Teacher login works
- [ ] Department login works
- [ ] Each role sees appropriate dashboard
- [ ] Each role cannot access other roles' screens

### Security ✓
- [ ] RoleProtectedScreen blocking unauthorized access
- [ ] Firestore rules deployed
- [ ] student/teacher/department queries blocked by role
- [ ] user_profile cannot be modified by users

### Data ✓
- [ ] Students can read own data
- [ ] Teachers can read all student data
- [ ] Department can read all data
- [ ] No cross-role data leaks

### Navigation ✓
- [ ] Named routes working
- [ ] AppRouter guards active
- [ ] Unauthorized navigation shows dialog
- [ ] Logout clears role correctly

### Performance ✓
- [ ] App starts quickly
- [ ] Role loads < 2 seconds after login
- [ ] Navigation transitions smooth
- [ ] No memory leaks on role changes

---

## Common Issues During Implementation

### Issue: "RoleManager not found" error

**Cause:** MultiProvider not set up properly in main.dart

**Solution:**
```dart
// Make sure main() has:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => RoleManager()),
    Provider(create: (_) => AuthService()),
  ],
  child: MaterialApp(...),
)
```

### Issue: Login page compiles but doesn't recognize AuthService

**Cause:** Import missing or AuthService not provided

**Solution:**
```dart
import 'package:test/services/auth_service.dart';
import 'package:test/services/role_manager.dart';

// In login:
final authService = context.read<AuthService>();
final roleManager = context.read<RoleManager>();
```

### Issue: "Access Denied" after successful login

**Cause:** user_profile document doesn't exist or role field is null

**Solution:**
1. Check Firebase Console → Firestore Data
2. Verify user_profile/{uid} exists
3. Verify role field is set: "student", "teacher", or "department"
4. If missing, run auth service to create it

### Issue: Firestore rules blocking valid queries

**Cause:** User doesn't have required role or rule logic is wrong

**Solution:**
1. Check user_profile role field
2. Enable Firestore debug logging
3. Verify rule syntax in `firestore.rules`
4. Test rules in Firebase Emulator first

---

## Timeline Estimate

Based on problem size:

| Phase | Time | Difficulty |
|-------|------|-----------|
| Phase 1: Setup Services | 30 min | Easy |
| Phase 2: Update App | 1-2 hrs | Medium |
| Phase 3: Migrate Screens | 2-4 hrs | Medium |
| Phase 4: Testing | 1-2 hrs | Hard |
| Phase 5: Documentation | 30 min | Easy |
| Phase 6: Deployment | 1 hr | Medium |
| **TOTAL** | **6-10 hrs** | - |

**Actual time depends on:**
- Number of existing screens to convert
- Complexity of your app
- Testing thoroughness needed
- Team's familiarity with provider/Firebase

---

## Success Criteria

✅ Implementation is complete when:

1. ✓ All new services created and compile
2. ✓ main.dart uses MultiProvider with RoleManager
3. ✓ All role-specific screens extend RoleProtectedScreen
4. ✓ RoleProtectedScreen blocks unauthorized access
5. ✓ Firestore rules deployed and enforced
6. ✓ Login works for all three roles correctly
7. ✓ Users routed to correct dashboard
8. ✓ Cross-role navigation blocked with message
9. ✓ Firestore queries enforced by role
10. ✓ All tests passing
11. ✓ No lint warnings
12. ✓ Documentation complete
13. ✓ Team reviewed and approved

---

## Getting Help

If stuck on a specific step:

1. **Step details:** Look in the detailed guides
   - ROLE_BASED_ACCESS_CONTROL_GUIDE.md
   - MIGRATION_TO_ROLE_BASED_SECURITY.md
   - QUICK_REFERENCE_ROLE_SECURITY.md

2. **Code examples:** Check protected_dashboards.dart

3. **Common issues:** See "Common Issues" section above

4. **Firestore issues:** Check firestore.rules file

---

**Ready to implement? Start with Phase 1! 🚀**

Once each phase is complete, mark it off above and move to the next one.

Good Luck! ✅
