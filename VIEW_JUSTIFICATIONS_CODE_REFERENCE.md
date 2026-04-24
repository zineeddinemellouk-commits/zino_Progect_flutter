# 📖 View Justifications - Code Reference & Examples

## Table of Contents
1. [File Location](#file-location)
2. [Core Methods](#core-methods)
3. [Usage Examples](#usage-examples)
4. [Customization](#customization)
5. [Troubleshooting](#troubleshooting)
6. [Common Patterns](#common-patterns)

---

## 📂 File Location

**Main Page:**
```
lib/pages/departement/VewJustification.dart
```

**Dependencies:**
- `lib/models/justification_model.dart` - Data model
- `lib/pages/departement/providers/student_management_provider.dart` - Provider
- `lib/helpers/localization_helper.dart` - Translations

---

## 🔧 Core Methods

### 1. `_buildHierarchy()` - Groups Data

**Purpose:** Convert flat list → hierarchical map

**Signature:**
```dart
Map<String, Map<String, List<JustificationModel>>> _buildHierarchy(
  List<JustificationModel> items,
)
```

**Example Usage:**
```dart
final items = snapshot.data ?? [];
final hierarchy = _buildHierarchy(items);

// Access structure
final level1Groups = hierarchy['L1'];        // Map<String, List>
final level1Group1Items = hierarchy['L1']['G1'];  // List<JustificationModel>
```

**Output Structure:**
```dart
{
  "L1": {
    "G1": [JustificationModel, JustificationModel, ...],
    "G2": [JustificationModel, ...],
  },
  "L2": {
    "G1": [JustificationModel, ...],
  },
}
```

---

### 2. `_buildLevelSection()` - Create Level UI

**Purpose:** Render expandable Level container with count

**Signature:**
```dart
Widget _buildLevelSection(
  BuildContext context,
  String levelName,           // e.g., "L1"
  Map<String, List<JustificationModel>> groupMap,
  int totalCount,             // Total justifications in level
)
```

**Example Usage:**
```dart
_buildLevelSection(
  context,
  "L1",
  {"G1": [...], "G2": [...]},
  15,  // 15 total justifications in L1
)
```

**Features:**
- ✅ Purple header with level name
- ✅ Green badge with total count
- ✅ Expandable (controlled by `_expandedLevels` set)
- ✅ Nested Groups inside

---

### 3. `_buildGroupSection()` - Create Group UI

**Purpose:** Render expandable Group container with justifications

**Signature:**
```dart
Widget _buildGroupSection(
  BuildContext context,
  String levelName,           // e.g., "L1"
  String groupName,           // e.g., "G1"
  List<JustificationModel> justifications,
)
```

**Example Usage:**
```dart
_buildGroupSection(
  context,
  "L1",
  "G1",
  [JustificationModel(...), ...],
)
```

**Features:**
- ✅ Blue header with group name
- ✅ Orange badge with count
- ✅ Expandable (controlled by `_expandedGroups` set)
- ✅ List of justification cards inside

---

### 4. `_showDetails()` - Show Details Dialog

**Purpose:** Display full justification details in modal

**Signature:**
```dart
void _showDetails(BuildContext context, JustificationModel item)
```

**Example Usage:**
```dart
_showDetails(context, justificationItem);
// Opens AlertDialog with full details, approve/reject buttons
```

**Dialog Features:**
- ✅ Level and Group info
- ✅ Student name, email
- ✅ Subject and teacher
- ✅ Dates (absence, submitted)
- ✅ Reason text
- ✅ Attachment link
- ✅ Approve/Reject buttons (if status='submitted')

---

## 💡 Usage Examples

### Example 1: Filter Justifications by Status

**Goal:** Show only "submitted" justifications

**Before Refactor (No hierarchy):**
```dart
final pending = items.where((j) => j.status == 'submitted').toList();

ListView.builder(
  itemCount: pending.length,
  itemBuilder: (context, index) {
    return _JustificationCard(item: pending[index], ...);
  },
)
```

**After Refactor (With hierarchy):**
```dart
// Filter before grouping
final filtered = items.where((j) => j.status == 'submitted').toList();
final hierarchy = _buildHierarchy(filtered);

// Then build as normal
```

---

### Example 2: Count Justifications per Level

**Goal:** Get total count for each level

```dart
Map<String, int> getCountPerLevel(
  Map<String, Map<String, List<JustificationModel>>> hierarchy,
) {
  final counts = <String, int>{};
  
  hierarchy.forEach((level, groups) {
    final total = groups.values.fold<int>(
      0,
      (sum, justifications) => sum + justifications.length,
    );
    counts[level] = total;
  });
  
  return counts;
}

// Usage
final hierarchy = _buildHierarchy(items);
final levelCounts = getCountPerLevel(hierarchy);
// levelCounts = {"L1": 18, "L2": 15, "L3": 12}
```

---

### Example 3: Find All Groups in a Level

**Goal:** Get all groups for a specific level

```dart
List<String> getGroupsInLevel(
  Map<String, Map<String, List<JustificationModel>>> hierarchy,
  String levelName,
) {
  return hierarchy[levelName]?.keys.toList() ?? [];
}

// Usage
final l1Groups = getGroupsInLevel(hierarchy, 'L1');
// l1Groups = ["G1", "G2", "G3"]
```

---

### Example 4: Expand All Levels Programmatically

**Goal:** Open all levels on page load

```dart
@override
void initState() {
  super.initState();
  
  // Fetch data and auto-expand
  Future.delayed(const Duration(milliseconds: 500), () {
    // This would require fetching hierarchy first
    // For now, just expand all on demand
  });
}

// Or use this method to expand all
void expandAll(Map<String, Map<String, List<JustificationModel>>> hierarchy) {
  setState(() {
    _expandedLevels.addAll(hierarchy.keys);
    
    // Also expand all groups
    hierarchy.forEach((level, groups) {
      groups.keys.forEach((group) {
        _expandedGroups.add('$level::$group');
      });
    });
  });
}

// Usage
final hierarchy = _buildHierarchy(items);
expandAll(hierarchy);
```

---

### Example 5: Get Specific Justification

**Goal:** Find justification by ID from hierarchy

```dart
JustificationModel? findJustificationById(
  Map<String, Map<String, List<JustificationModel>>> hierarchy,
  String justificationId,
) {
  for (final level in hierarchy.values) {
    for (final justifications in level.values) {
      try {
        return justifications.firstWhere((j) => j.id == justificationId);
      } catch (e) {
        continue;
      }
    }
  }
  return null;
}

// Usage
final j = findJustificationById(hierarchy, 'just_12345');
if (j != null) {
  print('Found: ${j.studentName}');
}
```

---

## 🎨 Customization

### Change Expansion Behavior

#### Make Levels Expanded by Default
**File:** `VewJustification.dart`, method `_buildLevelSection()`

**Find:**
```dart
initiallyExpanded: isExpanded,
```

**Change to:**
```dart
initiallyExpanded: true,  // Always expanded
```

---

#### Make Only One Level Expandable at a Time

**File:** `VewJustification.dart`, in `_buildLevelSection()`

**Add to `onExpansionChanged`:**
```dart
onExpansionChanged: (expanded) {
  setState(() {
    if (expanded) {
      _expandedLevels.clear();  // Clear all
      _expandedLevels.add(levelName);  // Add only this one
    } else {
      _expandedLevels.remove(levelName);
    }
  });
},
```

---

### Customize Colors

#### Change Level Color (Purple)
**Find all:**
```dart
Color(0xFF7C3AED)    // Purple hex
```

**Replace with:**
```dart
Color(0xFF3B82F6)    // Blue hex
Color(0xFF10B981)    // Green hex
Color(0xFFF59E0B)    // Orange hex
// Or any other hex code
```

---

#### Change Group Color (Blue)
**Find all:**
```dart
Color(0xFF2563EB)    // Blue hex
```

**Replace with:**
```dart
Color(0xFF7C3AED)    // Purple hex
// Or any other color
```

---

### Adjust Spacing

**Between Levels:**
```dart
const SizedBox(height: 12),  // Change 12 to desired height
```

**Between Groups:**
```dart
const SizedBox(height: 12),  // In _buildLevelSection
const SizedBox(height: 10),  // In _buildGroupSection
```

**Between Cards:**
```dart
const SizedBox(height: 10),  // In ListView.separated
```

---

### Change Card Size

**Justification Card Padding:**
```dart
child: Padding(
  padding: const EdgeInsets.all(12),  // Change 12 for more/less padding
  child: Column(
```

**Avatar Size:**
```dart
Container(
  width: 40,    // Change to 32, 48, 56, etc.
  height: 40,   // Match width
```

---

## 🔍 Troubleshooting

### Issue: Levels Not Showing

**Possible Causes:**
1. No justifications in Firestore
2. `levelName` is null
3. Provider not properly initialized

**Solution:**
```dart
// Add debug logs
print('Items count: ${items.length}');
items.forEach((item) {
  print('Item: ${item.studentName}, Level: ${item.levelName}, Group: ${item.groupName}');
});

final hierarchy = _buildHierarchy(items);
print('Hierarchy: $hierarchy');
```

---

### Issue: Groups Not Expanding

**Possible Causes:**
1. Group key collision (same level-group pair)
2. No items in group after filtering
3. UI not rebuilding

**Solution:**
```dart
// Verify group key generation
final groupKey = '$levelName::$groupName';
print('Group Key: $groupKey');
print('Is Expanded: ${_expandedGroups.contains(groupKey)}');

// Force rebuild
setState(() {});
```

---

### Issue: Performance Slow with Many Items

**Causes:**
- Too many items in single group (500+)
- Inefficient filtering

**Solutions:**
```dart
// 1. Pagination: Show 20 per group
List<JustificationModel> paginate(
  List<JustificationModel> items,
  int page,
  int pageSize,
) {
  final start = page * pageSize;
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

// 2. Lazy loading: Load groups on expand
// 3. Filter unnecessary fields
```

---

### Issue: Expansion State Not Persisting

**Cause:** Widget rebuilds on navigation

**Solution:** Use Provider or GetStorage
```dart
// Option 1: Save to localStorage
import 'package:get_storage/get_storage.dart';

final storage = GetStorage();

void _saveExpansionState() {
  storage.write('expandedLevels', _expandedLevels.toList());
  storage.write('expandedGroups', _expandedGroups.toList());
}

void _loadExpansionState() {
  final levels = storage.read<List>('expandedLevels') ?? [];
  final groups = storage.read<List>('expandedGroups') ?? [];
  
  setState(() {
    _expandedLevels.addAll(levels.cast<String>());
    _expandedGroups.addAll(groups.cast<String>());
  });
}

@override
void initState() {
  super.initState();
  _loadExpansionState();
}
```

---

## 🎯 Common Patterns

### Pattern 1: Auto-Expand First Level on Load

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  
  // Will need to fetch hierarchy first
  Future.microtask(() {
    if (mounted) {
      setState(() {
        // Expand first level
        if (hierarchyMap.isNotEmpty) {
          _expandedLevels.add(hierarchyMap.keys.first);
        }
      });
    }
  });
}
```

---

### Pattern 2: Search within Hierarchy

```dart
String _searchQuery = '';

Map<String, Map<String, List<JustificationModel>>> _filterHierarchy(
  Map<String, Map<String, List<JustificationModel>>> hierarchy,
  String query,
) {
  if (query.isEmpty) return hierarchy;
  
  final filtered = <String, Map<String, List<JustificationModel>>>{};
  
  hierarchy.forEach((level, groups) {
    final filteredGroups = <String, List<JustificationModel>>{};
    
    groups.forEach((group, justifications) {
      final filteredItems = justifications
          .where((j) => 
            j.studentName?.toLowerCase().contains(query.toLowerCase()) ?? false ||
            j.subject.toLowerCase().contains(query.toLowerCase()) ?? false
          )
          .toList();
      
      if (filteredItems.isNotEmpty) {
        filteredGroups[group] = filteredItems;
      }
    });
    
    if (filteredGroups.isNotEmpty) {
      filtered[level] = filteredGroups;
    }
  });
  
  return filtered;
}

// Usage in build
TextField(
  onChanged: (q) => setState(() => _searchQuery = q),
  decoration: InputDecoration(hintText: "Search..."),
)
```

---

### Pattern 3: Bulk Actions (Approve All in Group)

```dart
Future<void> approveAllInGroup(
  List<JustificationModel> justifications,
) async {
  final provider = context.read<StudentManagementProvider>();
  
  for (final item in justifications) {
    if (item.status == 'submitted') {
      await provider.updateJustificationStatus(
        id: item.id,
        status: 'accepted',
      );
    }
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Approved ${justifications.length} items')),
  );
}

// Usage
ElevatedButton(
  onPressed: () => approveAllInGroup(groupJustifications),
  child: const Text('Approve All'),
)
```

---

### Pattern 4: Export Group as CSV

```dart
String exportGroupAsCSV(
  String levelName,
  String groupName,
  List<JustificationModel> items,
) {
  final buffer = StringBuffer();
  buffer.writeln('Student,Subject,Teacher,Date,Status,Reason');
  
  for (final item in items) {
    buffer.writeln(
      '${item.studentName},'
      '${item.subject},'
      '${item.teacherName},'
      '${item.absenceDate.toIso8601String().split('T').first},'
      '${item.status},'
      '${item.reason ?? 'N/A'}'
    );
  }
  
  return buffer.toString();
}

// Usage
final csv = exportGroupAsCSV('L1', 'G1', groupJustifications);
// Save to file or share
```

---

### Pattern 5: Sort Groups by Custom Field

```dart
void sortGroupsByCount(Map<String, List<JustificationModel>> groups) {
  final entries = groups.entries.toList();
  entries.sort((a, b) => b.value.length.compareTo(a.value.length));
  
  final sorted = <String, List<JustificationModel>>{};
  for (final entry in entries) {
    sorted[entry.key] = entry.value;
  }
  
  return sorted;
}
```

---

## 📚 References

**Related Documentation:**
- [Complete Refactor Guide](JUSTIFICATIONS_HIERARCHICAL_REFACTOR.md)
- [Before & After Comparison](VIEW_JUSTIFICATIONS_BEFORE_AFTER.md)

**Flutter Docs:**
- [ExpansionTile API](https://api.flutter.dev/flutter/material/ExpansionTile-class.html)
- [State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt/intro)

---

## 🎓 Tips & Tricks

1. **Debugging Hierarchy**
   ```dart
   print(jsonEncode(hierarchy));  // See structure
   ```

2. **Efficient Filtering**
   ```dart
   // Bad: O(n²)
   for (final level in hierarchy.entries) {
     for (final group in level.value.entries) {
       for (final item in group.value) { /*...*/ }
     }
   }
   
   // Good: O(n)
   hierarchy.values.expand((g) => g.values)
     .expand((l) => l)
     .where((item) => /*...*/);
   ```

3. **Memory Conscious**
   ```dart
   // Don't constantly rebuild hierarchy
   late final hierarchy;
   
   @override
   Widget build(BuildContext context) {
     return StreamBuilder(
       stream: provider.watchJustifications(),
       builder: (context, snapshot) {
         if (snapshot.hasData) {
           hierarchy = _buildHierarchy(snapshot.data!);  // Build once per update
         }
         return _buildUI();
       },
     );
   }
   ```
