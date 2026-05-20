# 🚀 Skeleton Loading - Quick Reference

## One-Line Usage Guide

### For Lists & Grids
```dart
// Simple list with items
ListSkeleton(itemCount: 6)

// List with avatars and details
ListSkeleton(itemCount: 6, hasSubtitle: true, hasTrailing: true)

// Card grid layout
CardListSkeleton(itemCount: 6)
```

### For Dashboards
```dart
// Quick dashboard skeleton
DashboardSkeleton()

// Custom dashboard (pick what you need)
DashboardSkeleton(
  showHeader: true,
  showStats: true,
  showChart: true,
  showQuickActions: true,
)

// Just header
DashboardHeaderSkeleton()

// Just stats
StatCardSkeleton(cardCount: 3)

// Just chart
AttendanceChartSkeleton()
```

### For Profiles & Details
```dart
// Full profile page
ProfileSkeleton(
  showHeader: true,
  showStats: true,
  showDetails: true,
)

// Attendance records
AttendanceRecordSkeleton(recordCount: 5)

// History/Timeline
TimelineItemSkeleton(itemCount: 8)
```

### For Tables & Grids
```dart
// Generic table
TableSkeleton(rowCount: 10, columnCount: 4)

// Attendance table (specialized)
AttendanceTableSkeleton(rowCount: 10)

// Data grid
DataGridSkeleton(rowCount: 6, columnCount: 4)
```

### Custom Bones
```dart
// Single rectangle
SkeletonBone(width: 200, height: 16)

// Avatar circle
SkeletonCircle(radius: 30)

// Multiple text lines
SkeletonLine(lineCount: 3, height: 12)
```

---

## Page Type → Skeleton Mapping

| Page Type | Best Skeleton | Import |
|-----------|---|---|
| List/Feed | `ListSkeleton` | `card_skeleton.dart` |
| Attendance History | `TimelineItemSkeleton` | `profile_skeleton.dart` |
| Student/Teacher Cards | `CardListSkeleton` | `card_skeleton.dart` |
| Dashboard Overview | `DashboardSkeleton` | `dashboard_skeleton.dart` |
| Profile Page | `ProfileSkeleton` | `profile_skeleton.dart` |
| Data Table | `TableSkeleton` | `table_skeleton.dart` |
| Grid Layout | `DataGridSkeleton` | `table_skeleton.dart` |

---

## Standard Implementation Pattern

**Every page with data loading:**

```dart
import 'package:test/widgets/skeleton_widgets/skeleton_widgets.dart';

StreamBuilder<YourType>(
  stream: yourStream,
  builder: (context, snapshot) {
    // LOADING STATE - Show skeleton
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CardListSkeleton(itemCount: 6);  // ← Pick your skeleton here
    }

    // ERROR STATE - Keep as is
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    // SUCCESS STATE - Your real content
    final data = snapshot.data ?? [];
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) => YourWidget(data[index]),
    );
  },
)
```

---

## Pages Updated (15+)

✅ **Attendance Pages** (5)
- absence_tracker_page
- student_requests_page
- teacher_attendance_history_page
- teacher_attendance_groups_page
- teacher_group_attendance_page

✅ **Profile Pages** (2)
- teacher_profile_page
- students_page

✅ **Management Pages** (3)
- ViewStudent
- ViewTeachers
- ViewSubjects

✅ **Selection Pages** (3)
- teacher_level_selection_page
- teacher_subject_selection_page
- teacher_group_selection_page

---

## Colors & Animation

**Automatic colors** - No config needed:
- Base color: Light gray `#F0F0F0`
- Highlight color: Medium gray `#E8E8E8`
- Animation: Smooth 1200ms shimmer
- Works with light & dark themes

---

## DO's ✅

- ✅ Use skeletons for **page/stream loading**
- ✅ Match skeleton itemCount to expected data
- ✅ Use appropriate skeleton type for your layout
- ✅ Keep shimmer animation enabled
- ✅ Test on slow networks (Chrome DevTools)

## DON'Ts ❌

- ❌ Don't use skeletons for **button actions** (keep CircularProgressIndicator)
- ❌ Don't mix different skeleton types on same page
- ❌ Don't use skeletons for modal dialogs
- ❌ Don't disable animations for performance
- ❌ Don't modify SkeletonConfig colors frequently

---

## Import One Line

```dart
import 'package:test/widgets/skeleton_widgets/skeleton_widgets.dart';
```

**That's it! All skeletons are exported from this file.**

---

## Testing Checklist

- [ ] Page loads with skeleton (1-2 seconds)
- [ ] Skeleton smoothly animates
- [ ] Real content fades in when loaded
- [ ] No layout shift when content appears
- [ ] Works on mobile & tablet
- [ ] Dark mode colors correct
- [ ] No console errors

---

## Common Skeletons at a Glance

```dart
// Most common - use this 80% of the time
CardListSkeleton(itemCount: 6)

// For data tables & reports
TableSkeleton(rowCount: 10, columnCount: 4)

// For user profiles
ProfileSkeleton()

// For attendance/history
TimelineItemSkeleton(itemCount: 5)

// For detailed lists
ListSkeleton(itemCount: 6, hasSubtitle: true)

// For dashboards
DashboardSkeleton()
```

---

## Need Help?

See full implementation guide: [`SKELETON_LOADING_GUIDE.md`](SKELETON_LOADING_GUIDE.md)
