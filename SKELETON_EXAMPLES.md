# Skeleton Loading - Example Implementations

This file shows real code examples for implementing skeleton loading on your most important pages.

---

## Example 1: Department Dashboard

**File to Update:** `lib/pages/department_dashboard.dart`

**Before:**
```dart
class _DepartmentDashboardState extends State<DepartmentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: departmentAppBar(context, 'Dashboard'),
      drawer: departmentDrawer(context),
      body: FutureBuilder(
        future: Provider.of<StudentManagementProvider>(context, listen: false)
            .loadStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // ... rest of dashboard content
        },
      ),
    );
  }
}
```

**After:**
```dart
import 'package:test/widgets/skeletons/dashboard_skeleton.dart';

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: departmentAppBar(context, 'Dashboard'),
      drawer: departmentDrawer(context),
      body: FutureBuilder(
        future: Provider.of<StudentManagementProvider>(context, listen: false)
            .loadStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DashboardSkeleton();  // ← Changed this line
          }
          // ... rest of dashboard content
        },
      ),
    );
  }
}
```

---

## Example 2: Students List Page

**File to Update:** `lib/features/students/presentation/pages/students_page.dart`

**Pattern:**
```dart
import 'package:test/widgets/skeletons/students_list_skeleton.dart';

class _StudentsPageState extends State<StudentsPage> {
  bool isLoading = true;
  List<StudentModel> students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final provider = Provider.of<StudentProvider>(context, listen: false);
      students = await provider.getStudents();
      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading students: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const StudentsListSkeleton()  // ← Show skeleton while loading
        : Scaffold(
            body: ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                return StudentTile(student: students[index]);
              },
            ),
          );
  }
}
```

---

## Example 3: Teachers List Page

**File to Update:** `lib/pages/departement/ViewTeachers.dart`

**Change:**
```dart
import 'package:test/widgets/skeletons/teachers_list_skeleton.dart';

// In existing StreamBuilder:
StreamBuilder<List<TeacherModel>>(
  stream: FirestoreService().getTeachersStream(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const TeachersListSkeleton();  // ← Replace CircularProgressIndicator
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('No teachers found'));
    }
    return TeachersList(teachers: snapshot.data!);
  },
)
```

---

## Example 4: Absence Tracker Page

**File to Update:** `lib/features/students/presentation/pages/absence_tracker_page.dart`

**Change:**
```dart
import 'package:test/widgets/skeletons/attendance_skeleton.dart';

// In existing FutureBuilder or StreamBuilder:
if (snapshot.connectionState == ConnectionState.waiting) {
  return const AttendanceSkeleton();  // ← Replace CircularProgressIndicator
}
```

---

## Example 5: Add Student Form

**File to Update:** `lib/pages/departement/AddStudent.dart`

**Pattern:**
```dart
import 'package:test/widgets/skeletons/form_skeleton.dart';

class _AddStudentState extends State<AddStudent> {
  bool isLoading = false;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    // Load any required data (departments, classes, etc.)
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => isPageLoading = false);
    } catch (e) {
      setState(() => isPageLoading = false);
    }
  }

  Future<void> _submitForm() async {
    setState(() => isLoading = true);
    try {
      // Your form submission logic
      await provider.addStudent(formData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show skeleton while initializing
    if (isPageLoading) {
      return const FormSkeleton(title: 'Add Student', fieldCount: 5);
    }

    return Scaffold(
      // ... your form UI
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Add Student'),
      ),
    );
  }
}
```

---

## Example 6: Attendance History with StreamBuilder

**File to Update:** `lib/features/teachers/presentation/pages/teacher_attendance_history_page.dart`

**Change:**
```dart
import 'package:test/widgets/skeletons/attendance_skeleton.dart';

StreamBuilder<List<AttendanceRecord>>(
  stream: attendanceService.getAttendanceHistory(teacherId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const AttendanceSkeleton();  // ← Use skeleton
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(child: Text('No attendance records'));
    }
    
    return AttendanceList(records: snapshot.data!);
  },
)
```

---

## Example 7: Drawer Skeleton (Advanced)

**File to Update:** `lib/pages/role_home_page.dart`

**If drawer content loads from Firestore:**
```dart
import 'package:test/widgets/skeletons/drawer_skeleton.dart';

// In Scaffold:
drawer: StreamBuilder<UserProfile>(
  stream: authService.getUserProfileStream(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Drawer(child: DrawerSkeleton());
    }
    
    if (snapshot.hasError) {
      return Drawer(child: Center(child: Text('Error')));
    }
    
    return Drawer(
      child: ActualDrawerContent(profile: snapshot.data),
    );
  },
)
```

---

## Example 8: Subjects Grid Page

**File to Update:** `lib/pages/departement/ViewSubjects.dart`

**Change:**
```dart
import 'package:test/widgets/skeletons/subjects_list_skeleton.dart';

FutureBuilder<List<SubjectModel>>(
  future: subjectService.getSubjects(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SubjectsListSkeleton();  // ← Use grid skeleton
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    return SubjectGrid(subjects: snapshot.data ?? []);
  },
)
```

---

## Common Patterns

### Pattern 1: StreamBuilder (Real-Time Data)
```dart
StreamBuilder<List<T>>(
  stream: yourStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const YourSkeleton();  // Show skeleton
    }
    return YourContent(data: snapshot.data);
  },
)
```

### Pattern 2: FutureBuilder (One-Time Fetch)
```dart
FutureBuilder<List<T>>(
  future: yourFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const YourSkeleton();  // Show skeleton
    }
    return YourContent(data: snapshot.data);
  },
)
```

### Pattern 3: State-Based Loading
```dart
bool isLoading = true;

@override
void initState() {
  super.initState();
  _loadData();
}

Future<void> _loadData() async {
  try {
    await firestore.loadData();
    setState(() => isLoading = false);
  } catch (e) {
    setState(() => isLoading = false);
  }
}

@override
Widget build(BuildContext context) {
  return isLoading ? const Skeleton() : RealContent();
}
```

---

## Testing Your Skeletons

Add this to `initState()` or `FutureBuilder` to test skeleton display:

```dart
// Simulate 3-second load time
Future.delayed(
  const Duration(seconds: 3),
  () async {
    // Your actual data fetch
    return await firestore.getStudents();
  },
)
```

Or manually set `isLoading = true` and trigger state refresh to see skeleton.

---

## Debugging Tips

**Q: Skeleton shows but data isn't loading after?**
- Check that `setState(() => isLoading = false)` is being called
- Verify no exceptions are being swallowed
- Add print statements: `print('Loading...'); print('Done.');`

**Q: Skeleton layout doesn't match real page?**
- Compare dimensions in skeleton vs real page
- Check AppBar height, padding, border radius values
- Take screenshot of both side-by-side

**Q: Animation looks choppy?**
- Reduce list item count from 8 to 6
- Check device performance in debug mode
- Verify shimmer package is ^3.0.0+

---

## Files to Update (Priority Order)

1. `department_dashboard.dart` - Most visible
2. `students_screen.dart` - High usage
3. `ViewTeachers.dart` - High usage
4. `absence_tracker_page.dart` - Main feature
5. `AddStudent.dart` - Form pages
6. `teacher_attendance_history_page.dart`
7. `teacher_profile_page.dart`
8. Other list/grid pages

---

**Last Updated:** May 17, 2026  
**Ready to Apply:** Yes ✅
