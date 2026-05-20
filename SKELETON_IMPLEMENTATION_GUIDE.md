# Skeleton Loading System - Implementation Guide v2

## 🎯 Overview

Professional skeleton loading screens have been added to your Hodoori Smart Attendance app. These reusable shimmer widgets replace generic loaders with page-specific layouts that match your real content exactly.

## 📦 What Was Created

### Base Component
- **SkeletonBox** (`lib/widgets/skeleton_box.dart`) - Reusable shimmer building block

### Skeleton Widgets (8 Total)
1. **DashboardSkeleton** - Dashboard pages (department, role home, protected)
2. **StudentsListSkeleton** - Student list pages  
3. **TeachersListSkeleton** - Teacher list pages
4. **SubjectsListSkeleton** - Subject grid pages
5. **AttendanceSkeleton** - Attendance & history pages
6. **FormSkeleton** - Add/Edit form pages
7. **DrawerSkeleton** - Navigation drawer
8. (Custom skeletons can be created as needed)

### Configuration
- ✅ shimmer: ^3.0.0 added to pubspec.yaml
- AppBar Color: `Color(0xFF0F172A)`
- Background: `Color(0xFFF8FAFC)`
- Skeleton Base: `Color(0xFFE8EEF7)`
- Skeleton Highlight: `Color(0xFFF1F5F9)`

## 🚀 Quick Start - Integration Pattern

### For List Pages (Students, Teachers, Attendance, etc.)

```dart
// 1. Add import
import 'package:test/widgets/skeletons/students_list_skeleton.dart';

// 2. Add state variable
class _YourPageState extends State<YourPage> {
  bool isLoading = true;

  // 3. Fetch data
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Your Firestore/API call here
      await yourService.fetchData();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // 4. Conditional rendering
  @override
  Widget build(BuildContext context) {
    return isLoading 
        ? const StudentsListSkeleton()
        : YourActualPage();
  }
}
```

### For Dashboard Pages (Department, Role Home, etc.)

```dart
import 'package:test/widgets/skeletons/dashboard_skeleton.dart';

// Same pattern as above, but use DashboardSkeleton() instead
return isLoading 
    ? const DashboardSkeleton()
    : DashboardContent();
```

### For Form Pages (Add Student, Add Teacher, etc.)

```dart
import 'package:test/widgets/skeletons/form_skeleton.dart';

// Use FormSkeleton with field count
return isLoading 
    ? const FormSkeleton(title: 'Add Student', fieldCount: 5)
    : AddStudentForm();
```

### For Drawer Loading

```dart
import 'package:test/widgets/skeletons/drawer_skeleton.dart';

// In Scaffold drawer parameter
drawer: isDrawerLoading 
    ? const Drawer(child: DrawerSkeleton())
    : Drawer(child: ActualDrawerContent());
```

## 📋 Skeleton Types Reference

| Page Type | Skeleton | Item Count | File |
|-----------|----------|-----------|------|
| Department Dashboard | `DashboardSkeleton` | N/A | `dashboard_skeleton.dart` |
| Students List | `StudentsListSkeleton` | 8 rows | `students_list_skeleton.dart` |
| Teachers List | `TeachersListSkeleton` | 8 rows | `teachers_list_skeleton.dart` |
| Subjects List | `SubjectsListSkeleton` | 6 (2-col grid) | `subjects_list_skeleton.dart` |
| Attendance/History | `AttendanceSkeleton` | 6 rows | `attendance_skeleton.dart` |
| Add/Edit Forms | `FormSkeleton` | configurable | `form_skeleton.dart` |
| Navigation Drawer | `DrawerSkeleton` | 6 items | `drawer_skeleton.dart` |

## 🎨 Design Specifications

### AppBar Style
- **Gradient:** Blue gradient (#004AC6 → #2563EB)
- **Height:** 70px
- **Title:** Placeholder box (200px wide, 24px high)

### Card/Row Style
- **Padding:** 12px (items), 16px (page level)
- **Spacing:** 12px between items, 20px between sections
- **Border Radius:** 12-14px
- **Avatar:** 48x48px circles

### Colors (Hex)
- Base Color: `#E8EEF7` (light blue)
- Highlight Color: `#F1F5F9` (lighter blue)
- Avatar Placeholder: `#DBEA FE` (very light blue)
- Background: `#F8FAFC` (page background)

### Shimmer Animation
- Duration: 1200ms
- Effect: Smooth wave left-to-right
- Performance: ~5-10% CPU overhead

## ✅ Implementation Checklist

For each page you want to add skeleton loading:

- [ ] Choose correct skeleton from reference table
- [ ] Add import statement
- [ ] Add `bool isLoading = true;` state variable  
- [ ] Call data fetch method in `initState()`
- [ ] Wrap data fetch in try-catch
- [ ] Set `isLoading = false` after fetch completes
- [ ] Update build() with conditional: `isLoading ? SkeletonWidget() : RealContent()`
- [ ] Test by adding `Future.delayed(Duration(seconds: 2))` to simulate loading
- [ ] Verify skeleton layout matches real page layout
- [ ] Remove artificial delay before committing

## 🔧 Advanced Customization

### Create Custom Skeleton for Unique Page

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:test/widgets/skeleton_box.dart';

class MyCustomSkeleton extends StatelessWidget {
  const MyCustomSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const SkeletonBox(width: 200, height: 24),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Your custom skeleton layout here
          Shimmer.fromColors(
            baseColor: const Color(0xFFE8EEF7),
            highlightColor: const Color(0xFFF1F5F9),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF7),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Adjust Item Count for FormSkeleton

```dart
// For form with 7 fields
const FormSkeleton(fieldCount: 7)

// For form with 3 fields
const FormSkeleton(title: 'Edit Profile', fieldCount: 3)
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Skeleton doesn't match page layout | Verify exact spacing/dimensions against real page; update skeleton proportions |
| Shimmer looks choppy | Ensure device at 60+ FPS; reduce item count in lists |
| Colors mismatched | Double-check hex codes; ensure no color overrides elsewhere |
| Skeleton shows too long | Reduce Firestore query time; add timeout with error fallback |
| Page seems unresponsive | Add timeout (~5s) with error state to prevent indefinite loading |

## 📱 Which Pages Need Skeleton Loading?

### Immediate Priority (High User Impact)
- Department Dashboard
- Student List Pages
- Teacher List Pages  
- Absence Tracker
- Attendance History
- Add Student/Teacher Forms

### Medium Priority
- Subject Pages
- Department Settings
- Student Profile Pages
- Teacher Profile Pages

### Lower Priority (Usually Quick Load)
- Drawer Content
- Role Selection Pages
- Subject Selection Pages

## 🎯 Next Steps

1. **Choose 2-3 high-priority pages** (e.g., Department Dashboard, Students List)
2. **Apply skeleton loading** using the Quick Start pattern above
3. **Test loading state** with artificial delay
4. **Iterate** on remaining pages
5. **Monitor performance** in debug mode
6. **Deploy** when satisfied

## 📚 File Locations

All skeleton widgets are in: `lib/widgets/skeletons/`

```
lib/widgets/
├── skeleton_box.dart                 (base component)
└── skeletons/
    ├── dashboard_skeleton.dart
    ├── students_list_skeleton.dart
    ├── teachers_list_skeleton.dart
    ├── subjects_list_skeleton.dart
    ├── attendance_skeleton.dart
    ├── form_skeleton.dart
    └── drawer_skeleton.dart
```

## 💡 Pro Tips

- **Realistic Loading Times:** Use skeletons for anything that takes >500ms to load
- **Error Handling:** Show error state if loading exceeds 5 seconds
- **Partial Content:** Show skeleton only for sections being loaded (don't skeleton entire page if not needed)
- **Performance:** Use `const` constructors — they're optimized by Flutter's compiler
- **Testing:** Add print statements in setState to debug loading states

---

**Status:** ✅ Ready to implement  
**Date Created:** May 17, 2026  
**Shimmer Version:** ^3.0.0
