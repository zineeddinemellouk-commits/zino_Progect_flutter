# 🔄 Migration Guide - Converting Existing Screens to Use Role-Based Security

This guide shows how to convert your existing screens to use the new role-based access control system.

---

## Before and After Examples

### Example 1: Teacher Profile Page

#### ❌ BEFORE (Vulnerable)

```dart
class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({
    required this.teacherId,
    required this.teacherEmail,
  });

  final String teacherId;
  final String teacherEmail;

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  @override
  Widget build(BuildContext context) {
    // ❌ NO ROLE CHECK - Anyone can access this page!
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Profile')),
      body: const Center(child: Text('Teacher data here')),
    );
  }
}
```

**Problems:**
- ❌ No role verification
- ❌ Any user can navigate here directly
- ❌ No access control at screen level

#### ✅ AFTER (Secure)

```dart
class TeacherProfilePage extends RoleProtectedScreen {
  const TeacherProfilePage({super.key});

  @override
  UserRole get requiredRole => UserRole.teacher;

  @override
  Widget buildContent(BuildContext context) {
    // ✅ Only teachers can reach this code
    final roleManager = context.read<RoleManager>();
    final userId = roleManager.currentUserId;
    final email = roleManager.currentUserEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Profile')),
      body: Column(
        children: [
          Text('Email: $email'),
          Text('User ID: $userId'),
          // Teacher-specific content
        ],
      ),
    );
  }
}
```

**Benefits:**
- ✅ Role verified automatically
- ✅ Non-teachers see "Access Denied"
- ✅ Redirects to appropriate dashboard

---

### Example 2: Student Dashboard

#### ❌ BEFORE (Vulnerable)

```dart
class StudentsPage extends StatefulWidget {
  const StudentsPage({
    required this.selfViewOnly,
    required this.studentDocumentId,
    required this.studentEmail,
  });

  final bool selfViewOnly;
  final String studentDocumentId;
  final String studentEmail;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  @override
  Widget build(BuildContext context) {
    // ❌ Relies on constructor parameters - can be faked!
    // ❌ No verification of role
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    // Content here
    return const SizedBox();
  }
}
```

**Problems:**
- ❌ Parameters passed in can be manipulated
- ❌ No server-side verification
- ❌ Teacher could pass `studentDocumentId` and access student data
- ❌ No role enforcement

#### ✅ AFTER (Secure)

```dart
class StudentDashboard extends RoleProtectedScreen {
  const StudentDashboard({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    // ✅ Role verified before this code runs
    final roleManager = context.read<RoleManager>();
    final userId = roleManager.currentUserId!; // Safe to use - role verified
    final email = roleManager.currentUserEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: StreamBuilder(
        stream: _getStudentData(userId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildDashboard(snapshot.data);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Stream<Map<String, dynamic>?> _getStudentData(String uid) {
    return FirebaseFirestore.instance
        .collection('student')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Widget _buildDashboard(Map<String, dynamic>? data) {
    if (data == null) return const Center(child: Text('No data'));
    return Center(
      child: Text('Student: ${data['name']}'),
    );
  }
}
```

**Benefits:**
- ✅ Role verified automatically
- ✅ UID obtained from authenticated user (not parameter)
- ✅ Non-students cannot access
- ✅ Server-side Firestore rules enforce further

---

### Example 3: Department Page

#### ❌ BEFORE (Vulnerable)

```dart
class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard();

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  // ❌ Could show sensitive admin data to anyone who navigates here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department')),
      body: _buildAdminPanel(),
    );
  }

  Widget _buildAdminPanel() {
    // Shows all users, reports, etc.
    return const SizedBox();
  }
}
```

**Problems:**
- ❌ No access control
- ❌ Sensitive admin panel exposed
- ❌ Teachers/students could access

#### ✅ AFTER (Secure)

```dart
class DepartmentDashboard extends RoleProtectedScreen {
  const DepartmentDashboard({super.key});

  @override
  UserRole get requiredRole => UserRole.department;

  @override
  Widget buildContent(BuildContext context) {
    // ✅ Only department users see this
    return Scaffold(
      appBar: AppBar(title: const Text('Department Administration')),
      body: _buildAdminPanel(context),
    );
  }

  Widget _buildAdminPanel(BuildContext context) {
    return ListView(
      children: [
        _buildAdminSection(
          context,
          icon: Icons.people,
          title: 'User Management',
          onTap: () {
            // Navigate to user management (also protected)
          },
        ),
        _buildAdminSection(
          context,
          icon: Icons.analytics,
          title: 'View Reports',
          onTap: () {
            // Navigate to reports
          },
        ),
      ],
    );
  }

  Widget _buildAdminSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
```

**Benefits:**
- ✅ Only department users can access
- ✅ Teachers/students see "Access Denied"
- ✅ Clear admin panel organization
- ✅ Easy to add more admin features

---

## Conversion Checklist

For each existing screen, follow this checklist:

```
Screen Name: ____________________

□ Does the screen show role-specific content?
  
□ Change from StatefulWidget/StatelessWidget to RoleProtectedScreen
  
□ Implement required methods:
  ├─ UserRole get requiredRole
  └─ Widget buildContent(BuildContext context)

□ Remove constructor parameters for userId/role/email
  ├─ Instead use: context.read<RoleManager>().currentUserId
  ├─ Instead use: context.read<RoleManager>().currentUserEmail
  └─ Instead use: context.read<RoleManager>().currentRole

□ Update any role-checking code:
  ├─ From: if (userRole == 'student')
  └─ To: context.read<RoleManager>().isStudent

□ Test with different roles:
  ├─ Login as student - verify access
  ├─ Login as teacher - verify "Access Denied"
  └─ Login as department - verify appropriate access

□ Update any navigation to this screen:
  ├─ Ensure used via named route (e.g., '/student-dashboard')
  └─ Use AppRouter or tryNavigate() for guarded navigation

□ Check for hardcoded UIDs or emails in screen
  ├─ Replace with roleManager values
  └─ Never pass sensitive IDs as constructor parameters
```

---

## Pattern: Multi-Role Access

For screens accessible by multiple roles (e.g., attendance for both teacher and student):

```dart
// Option 1: Override allowedRoles
class AttendanceScreen extends RoleProtectedScreen {
  const AttendanceScreen({super.key});

  @override
  UserRole get requiredRole => UserRole.student; // Fallback

  @override
  List<UserRole>? get allowedRoles => [UserRole.student, UserRole.teacher];

  @override
  Widget buildContent(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    
    return Scaffold(
      body: roleManager.isStudent 
        ? _buildStudentView(context)
        : _buildTeacherView(context),
    );
  }

  Widget _buildStudentView(BuildContext context) {
    // Student sees only their attendance
    return const SizedBox();
  }

  Widget _buildTeacherView(BuildContext context) {
    // Teacher sees all student attendance
    return const SizedBox();
  }
}
```

---

## Pattern: Fine-Grained Feature Control

Hide features based on role within a screen:

```dart
class StudentDashboard extends RoleProtectedScreen {
  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Always visible
          _buildBasicInfo(context),
          
          // Only for students
          RoleConditional(
            requiredRole: UserRole.student,
            child: _buildAbsenceTracking(context),
          ),
          
          // Multi-role
          MultiRoleConditional(
            allowedRoles: [UserRole.teacher, UserRole.department],
            child: _buildReports(context),
          ),
        ],
      ),
    );
  }
}
```

---

## Pattern: Role-Based Data Fetching

```dart
// ❌ WRONG - No role verification
class UserDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('student')
          .doc('any-uid-here') // ❌ Not verified!
          .get(),
    );
  }
}

// ✅ CORRECT - Verified role and UID
class UserDataScreen extends RoleProtectedScreen {
  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    final userId = context.read<RoleManager>().currentUserId!;
    
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('student')
          .doc(userId) // ✅ Verified user
          .get(),
    );
  }
}
```

---

## Updating Navigation

### ❌ BEFORE

```dart
// Vulnerable navigation
_navigateToStudent() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StudentsPage(
        selfViewOnly: true,
        studentDocumentId: 'any-id-can-go-here', // ❌
        studentEmail: 'any-email@example.com', // ❌
      ),
    ),
  );
}
```

### ✅ AFTER

```dart
// Secure navigation using named routes
_navigateToDashboard() {
  Navigator.pushNamed(context, '/student-dashboard');
  // Or with guard:
  // context.tryNavigate('/student-dashboard');
}
```

---

## Updating main.dart Routes

```dart
MaterialApp(
  routes: {
    '/login': (_) => const LoginPage(),
    
    // ✅ Protected routes using RoleProtectedScreen
    '/student-dashboard': (_) => const StudentDashboard(),
    '/teacher-dashboard': (_) => const TeacherDashboard(),
    '/department-dashboard': (_) => const DepartmentDashboard(),
    
    // ✅ Multi-role screens
    '/attendance': (_) => const AttendanceScreen(),
  },
)
```

---

## Testing Your Updates

```dart
// Test 1: Verify role check works
testWidgets('StudentDashboard blocks non-students', (tester) async {
  // Setup: Login as teacher
  // Navigate to /student-dashboard
  // Expect: "Access Denied" shown
  expect(find.text('Access Denied'), findsOneWidget);
});

// Test 2: Verify role-based content
testWidgets('StudentDashboard shows content for students', (tester) async {
  // Setup: Login as student
  // Navigate to /student-dashboard
  // Expect: Content shown (not Access Denied)
  expect(find.byType(StudentDashboard), findsOneWidget);
});

// Test 3: Verify role-based UI elements
testWidgets('Student can see absence tracking', (tester) async {
  // Setup: Login as student
  // Navigate to /student-dashboard
  // Expect: Absence tracking button visible
  expect(find.text('Absences'), findsOneWidget);
});
```

---

## Common Patterns for Your App

### Pattern 1: Absence Tracker (Students can see, teachers manage)

```dart
class AbsenceTrackerPage extends RoleProtectedScreen {
  const AbsenceTrackerPage({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  List<UserRole>? get allowedRoles => [UserRole.student];

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
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _buildAbsenceList(snapshot.data!.docs);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAbsenceList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        // Build absence item
        return const SizedBox();
      },
    );
  }
}
```

### Pattern 2: Teacher Attendance (Teachers only)

```dart
class TeacherAttendancePage extends RoleProtectedScreen {
  const TeacherAttendancePage({super.key});

  @override
  UserRole get requiredRole => UserRole.teacher;

  @override
  Widget buildContent(BuildContext context) {
    final teacherId = context.read<RoleManager>().currentUserId!;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Record Attendance')),
      body: _buildAttendanceForm(teacherId),
    );
  }

  Widget _buildAttendanceForm(String teacherId) {
    return const SizedBox();
  }
}
```

### Pattern 3: Department Reports (Department only)

```dart
class DepartmentReportsPage extends RoleProtectedScreen {
  const DepartmentReportsPage({super.key});

  @override
  UserRole get requiredRole => UserRole.department;

  @override
  Widget buildContent(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Reports')),
      body: _buildReportsDashboard(),
    );
  }

  Widget _buildReportsDashboard() {
    return const SizedBox();
  }
}
```

---

## Troubleshooting Migration

### Issue: Compilation errors after conversion

**Solution:** Check you're using the right imports:
```dart
import 'package:test/widgets/role_protected_screen.dart';
import 'package:test/services/role_manager.dart';
import 'package:provider/provider.dart';
```

### Issue: Black screen after navigation

**Solution:** Ensure RoleManager is initialized:
```dart
// In your login flow
await roleManager.initializeFromFirestore();
```

### Issue: "Access Denied" appearing for authorized users

**Solution:** Check that Firestore user_profile document exists with correct role

### Issue: Build context not available

**Solution:** Use `context.read<RoleManager>()` in `buildContent()`, not `build()`

---

## Summary

Convert screens in this order:

1. **Priority 1:** Sensitive admin/department screens
2. **Priority 2:** Role-specific dashboards  
3. **Priority 3:** Feature pages (attendance, absences, etc.)
4. **Priority 4:** Shared/utility screens

Each conversion follows the same pattern:
- Extend `RoleProtectedScreen`
- Implement `requiredRole` and `buildContent()`
- Use `RoleManager` to get user info
- Update navigation to use named routes
- Test with different roles

You'll have complete role-based access control throughout your entire app! ✅
