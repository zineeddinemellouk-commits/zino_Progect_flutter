# View Justification Page - Code Structure Reference

## File Location
```
lib/pages/departement/VewJustification.dart
```

## Class Hierarchy

```
VewJustification (StatelessWidget)
├── Main screen
├── StreamBuilder for data
├── Calls: _organizeHierarchical()
├── Calls: _showDetails()
└── Renders: _LevelSection widgets

_LevelSection (StatefulWidget)
├── State: _LevelSectionState
├── Animation: expand/collapse
├── header: Level badge + count
└── Renders: _GroupSection widgets

_LevelSectionState (State)
├── Properties:
│   ├── _expandController: AnimationController
│   ├── _expandAnimation: Animation<double>
│   └── _isExpanded: bool
└── Methods:
    ├── initState()
    ├── dispose()
    ├── _toggleExpanded()
    └── build()

_GroupSection (StatefulWidget)
├── State: _GroupSectionState
├── Animation: expand/collapse
├── Header: Group badge + count
└── Renders: _JustificationCard widgets

_GroupSectionState (State)
├── Properties:
│   ├── _expandController: AnimationController
│   ├── _expandAnimation: Animation<double>
│   └── _isExpanded: bool
└── Methods:
    ├── initState()
    ├── dispose()
    ├── _toggleExpanded()
    └── build()

_JustificationCard (StatelessWidget)
├── Displays: Individual justification
├── Avatar, name, email
├── Subject, teacher, date
├── Status badge
├── Reason preview
└── onTap callback

_JustificationDetailsDialog (StatefulWidget)
└── (Preserved from original)

_HierarchicalLevel (Data class)
├── levelName: String
└── groups: List<_HierarchicalGroup>

_HierarchicalGroup (Data class)
├── groupName: String
└── items: List<JustificationModel>
```

---

## Key Methods

### VewJustification

#### `_organizeHierarchical(List<JustificationModel> items)`
```dart
List<_HierarchicalLevel> _organizeHierarchical(List<JustificationModel> items)
```
- **Purpose**: Converts flat list into hierarchical structure
- **Input**: List of JustificationModel objects
- **Process**: 
  1. Create nested Maps: `Level → Group → Items`
  2. Filter out empty levels/groups automatically
  3. Convert to _HierarchicalLevel objects
- **Output**: List of _HierarchicalLevel ready for UI
- **Time Complexity**: O(n) where n = number of justifications
- **Space Complexity**: O(n)

```dart
Map<String, Map<String, List<JustificationModel>>> hierarchy = {};

// Step 1: Build hierarchy
for (final item in items) {
  final levelName = item.levelName ?? 'Unknown Level';
  final groupName = item.groupName ?? 'Unknown Group';
  
  hierarchy.putIfAbsent(levelName, () => {});
  hierarchy[levelName]!.putIfAbsent(groupName, () => []);
  hierarchy[levelName]![groupName]!.add(item);
}

// Step 2: Convert to widget models (empty levels/groups filtered)
return hierarchy.entries
    .map((levelEntry) => _HierarchicalLevel(...))
    .toList();
```

#### `_showDetails(BuildContext context, JustificationModel item)`
```dart
void _showDetails(BuildContext context, JustificationModel item)
```
- **Purpose**: Show justification details in dialog
- **Triggers**: Approve/Reject functionality
- **Uses**: _JustificationDetailsDialog widget
- **Callbacks**: 
  - `onApprove`: Calls `updateJustificationStatus(status: 'accepted')`
  - `onReject`: Calls `updateJustificationStatus(status: 'refused')`

---

### _LevelSectionState

#### `_toggleExpanded()`
```dart
void _toggleExpanded()
```
- **Purpose**: Toggle expand/collapse state of level
- **Triggers**:
  1. Updates `_isExpanded` boolean
  2. Forwards (_isExpanded) or reverses animation controller
  3. setState() updates UI
- **Animation**: 300ms ease-in-out

```dart
void _toggleExpanded() {
  setState(() => _isExpanded = !_isExpanded);
  if (_isExpanded) {
    _expandController.forward();
  } else {
    _expandController.reverse();
  }
}
```

#### `build(BuildContext context)`
- **Purpose**: Constructs level UI
- **Returns**: Container with header + animated content
- **Content only shows if `_isExpanded`**
- **Uses**: ScaleTransition for smooth appearance

```dart
@override
Widget build(BuildContext context) {
  return Container(
    decoration: ..., // Card style
    child: Column(
      children: [
        // Header (always visible)
        Material(
          child: InkWell(
            onTap: _toggleExpanded,
            child: Padding(...)
          ),
        ),
        // Content (only if expanded)
        if (_isExpanded)
          ScaleTransition(
            scale: _expandAnimation,
            child: Column(
              children: [
                for (final group in widget.groups)
                  _GroupSection(...)
              ],
            ),
          ),
      ],
    ),
  );
}
```

#### `_getTotalCount()`
```dart
int _getTotalCount()
```
- **Purpose**: Calculate total justifications in level
- **Used**: Display in count badge
- **Calculation**: Sum of all items in all groups

```dart
int _getTotalCount() {
  return widget.groups.fold<int>(
    0,
    (sum, group) => sum + group.items.length,
  );
}
```

---

### _GroupSectionState

#### Similar to _LevelSectionState
- Same pattern for `_toggleExpanded()`
- Same pattern for `build()`
- Shows group-level items directly instead of child groups

---

### _JustificationCard

#### `build(BuildContext context)`
- **Purpose**: Constructs individual card UI
- **Layout**:
  1. Avatar row with student name, email, status
  2. Subject/teacher container
  3. Optional reason preview
- **OnTap**: Triggers `_showDetails()` callback

```dart
@override
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: statusColor.withOpacity(0.2)),
      boxShadow: [...],
    ),
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Row 1: Avatar + Name/Email + Status
            Row(...),
            SizedBox(height: 10),
            // Row 2: Subject/Teacher
            Container(...),
            // Row 3 (optional): Reason
            if (item.reason != null && item.reason!.isNotEmpty)
              Container(...)
          ],
        ),
      ),
    ),
  );
}
```

---

## StreamBuilder Flow

```
VewJustification.build()
           ↓
StreamBuilder<List<JustificationModel>>
           ↓
Listening to: provider.watchJustifications()
           ↓
Connection states handled:
├─ waiting     → CircularProgressIndicator
├─ error       → Error container with message
├─ data empty  → Empty state widget
└─ data ready  → _organizeHierarchical() → _LevelSection widgets
           ↓
Updates whenever watchJustifications() emits new data
```

---

## Animation Flow

### Expand Animation

```
_toggleExpanded() called
           ↓
_isExpanded = true
           ↓
_expandController.forward()
           ↓
AnimationController runs 0→1 over 300ms
           ↓
EaseInOut curve applies smooth acceleration
           ↓
_expandAnimation updates (0.0 → 1.0)
           ↓
AnimatedRotation applies icon rotation (0° → 180°)
           ↓
ScaleTransition applies scale (0 → 1.0)
           ↓
Content smoothly appears and scales up
```

### Collapse Animation

```
_toggleExpanded() called
           ↓
_isExpanded = false
           ↓
_expandController.reverse()
           ↓
AnimationController runs 1→0 over 300ms
           ↓
EaseInOut curve applies smooth deceleration
           ↓
_expandAnimation updates (1.0 → 0.0)
           ↓
AnimatedRotation applies icon rotation (180° → 0°)
           ↓
ScaleTransition applies scale (1.0 → 0)
           ↓
Content smoothly disappears and scales down
```

---

## Data Flow Diagram

```
Firestore Collection
     "justifications"
           ↓
StudentManagementProvider
  .watchJustifications()
           ↓
StreamController<List<JustificationModel>>
           ↓
VewJustification StreamBuilder
           ↓
_organizeHierarchical()
     (CPU-side processing)
           ↓
List<_HierarchicalLevel>
           ↓
ListView.separated
  (itemCount: levels.length)
           ↓
_LevelSection(levelIndex)
  [expanded: true by default]
           ↓
_GroupSection(groupIndex)
  [expanded: true by default]
           ↓
_JustificationCard(cardIndex)
  [clickable: true]
           ↓
User tap
  onTap → _showDetails()
           ↓
_JustificationDetailsDialog
  .showDialog()
           ↓
User action (Approve/Reject)
           ↓
provider.updateJustificationStatus()
           ↓
Firestore update
           ↓
watchJustifications() emits new list
           ↓
StreamBuilder rebuilds (full list)
  [_organizeHierarchical() re-runs]
           ↓
UI updates with new hierarchical structure
           ↓
Expansion states reset to defaults
```

---

## State Management

### VewJustification
- **Type**: StatelessWidget (no local state)
- **State**: Provided by `StudentManagementProvider` via watch()
- **Rebuilds**: On every snapshot from watchJustifications()

### _LevelSection
- **Type**: StatefulWidget
- **State**:
  - `_isExpanded`: bool (default: true)
  - `_expandController`: AnimationController
  - `_expandAnimation`: Animation<double>
- **Rebuilds**: Only when _toggleExpanded() called
- **Disposal**: AnimationController disposed in dispose()

### _GroupSection
- **Type**: StatefulWidget
- **State**: Same as _LevelSection
- **Rebuilds**: Only when _toggleExpanded() called
- **Disposal**: AnimationController disposed in dispose()

### _JustificationCard
- **Type**: StatelessWidget (no local state)
- **State**: Immutable, passed as parameters
- **Rebuilds**: Only when parameters change

---

## Performance Considerations

### Widget Creation
```
Initial Creation:
└─ VewJustification (1)
   └─ _LevelSection (N levels)
      └─ _GroupSection (M groups per level)
         └─ _JustificationCard (K cards per group)

Total Widgets: 1 + N + (N*M) + (N*M*K)
```

### Rebuild Triggers

| Trigger | Scope | Performance |
|---------|-------|-------------|
| watch() emits new list | Entire StreamBuilder | Full rebuild (necessary) |
| _toggleExpanded() called | Single Level/Group | Local setState (efficient) |
| Level state change | That _LevelSection only | Isolated (efficient) |
| Group state change | That _GroupSection only | Isolated (efficient) |

### Optimization Strategies

1. **Lazy Build**
   - Cards only built when group expanded
   - Groups only built when level expanded
   - Result: Fewer widgets when collapsed

2. **Efficient Animation**
   - Uses ScaleTransition (hardware accelerated)
   - AnimatedRotation (lightweight)
   - No expensive repaints

3. **Smart Organization**
   - _organizeHierarchical() runs once per data update
   - Empty levels/groups filtered at organization time
   - No wasted widgets

4. **Single Responsibility**
   - Each widget handles only its own expansion
   - No cross-widget state sharing
   - Easy to optimize individual sections

---

## Constants & Configuration

### Animation Timings
```dart
Duration _expandDuration = const Duration(milliseconds: 300);
Curve _expandCurve = Curves.easeInOut;
```

### Colors
```dart
// Levels
levelBgColor = const Color(0xFFEEF2FF);
levelIconColor = const Color(0xFF6366F1);
levelTextColor = const Color(0xFF4F46E5);

// Groups  
groupBgColor = const Color(0xFFDBEAFE);
groupIconColor = const Color(0xFF3B82F6);
groupTextColor = const Color(0xFF1E40AF);

// Status
statusSubmittedColor = Colors.orange;
statusAcceptedColor = Colors.green;
statusRefusedColor = Colors.red;

// Cards
reasonBgColor = const Color(0xFFFEF3C7);
reasonBorderColor = const Color(0xFFFCD34D);
```

### Sizing
```dart
levelBorderRadius = BorderRadius.circular(12);
groupBorderRadius = BorderRadius.circular(10);
cardBorderRadius = BorderRadius.circular(12);

levelPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
groupPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 12);
cardPadding = EdgeInsets.all(14);
```

---

## Error Handling

### Data Level
- Empty list → Shows empty state widget
- No level name → Uses 'Unknown Level'
- No group name → Uses 'Unknown Group'
- No student name → Uses 'Unknown Student'

### Widget Level
- Missing file → Hidden (gracefully)
- Missing reason → Reason container hidden
- Missing email → Shows '-'

### Firestore Level
- Query error → Caught by StreamBuilder.error state
- Permission denied → Shown in error container
- Network error → Caught and displayed

---

## Localization

All user-facing strings support i18n:
```dart
context.tr('justification_requests')
context.tr('pending_requests')
context.tr('level')
context.tr('group')
context.tr('accepted')
context.tr('refused')
context.tr('submitted')
context.tr('error')
context.tr('no_justifications')
// ... and more
```

No hardcoded English strings in UI.

---

## Testing Checklist

### Unit Tests (if added)
- [ ] _organizeHierarchical() correctly groups items
- [ ] Empty groups filtered out
- [ ] Empty levels filtered out
- [ ] Total count calculation correct

### Widget Tests
- [ ] _LevelSection expands/collapses
- [ ] _GroupSection expands/collapses
- [ ] Animations run for 300ms
- [ ] Icons rotate correctly
- [ ] Cards display all information

### Integration Tests
- [ ] Tap card → details dialog opens
- [ ] Click approve → status updates
- [ ] Click reject → status updates
- [ ] File link launches
- [ ] Localization strings display

### Manual Tests
- [ ] Smooth animations
- [ ] No jank or freezing
- [ ] Touch targets adequate (>48px)
- [ ] Works on different screen sizes
- [ ] Works on Android, iOS, Web

---

**Code Reference: ✅ Complete and documented!**
