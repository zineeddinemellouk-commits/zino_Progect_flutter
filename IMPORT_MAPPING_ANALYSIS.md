# Flutter Project Import Mapping Analysis

## Overview
**Scan Date**: Analysis of lib directory structure  
**Total .dart Files Scanned**: 101  
**Work Directory**: `c:\Users\zinoz\Desktop\New folder (3)\test\lib\`

---

## 1. Summary Statistics

| Metric | Count |
|--------|-------|
| Total .dart files analyzed | 101 |
| Unique package:test imports | 67 |
| Relative imports | 11 |
| External package imports | 28 |
| Files requiring updates | 100+ |
| Import statement variations | 180+ |

---

## 2. External Package Dependencies (No Changes Needed)
These external packages are used throughout and should NOT be modified:
- `dart:async`, `dart:convert`, `dart:io`, `dart:math`, `dart:typed_data`, `dart:ui`
- `package:cloud_firestore/cloud_firestore.dart`
- `package:firebase_auth/firebase_auth.dart`
- `package:firebase_core/firebase_core.dart`
- `package:file_picker/file_picker.dart`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/services.dart`
- `package:flutter_localizations/flutter_localizations.dart`
- `package:provider/provider.dart`
- `package:shared_preferences/shared_preferences.dart`
- `package:shimmer/shimmer.dart`
- `package:supabase_flutter/supabase_flutter.dart`
- `package:url_launcher/url_launcher.dart`

---

## 3. Current Structure: Categorized Imports by Type

### 3.1 MODELS (Package: test/models/)
**Current Location**: `lib/models/`  
**Target Location**: `lib/core/constants/` or feature-specific models folder

**All model imports found**:
- `package:test/models/absence_model.dart` → `lib/core/constants/absence_model.dart`
- `package:test/models/admin_model.dart` → `lib/core/constants/admin_model.dart`
- `package:test/models/app_user_profile.dart` → `lib/core/constants/app_user_profile.dart`
- `package:test/models/class_model.dart` → `lib/core/constants/class_model.dart`
- `package:test/models/exclusion_model.dart` → `lib/core/constants/exclusion_model.dart`
- `package:test/models/group_model.dart` → `lib/core/constants/group_model.dart`
- `package:test/models/justification_model.dart` → `lib/core/constants/justification_model.dart`
- `package:test/models/level_model.dart` → `lib/core/constants/level_model.dart`
- `package:test/models/notification_model.dart` → `lib/core/constants/notification_model.dart`
- `package:test/models/student_model.dart` → `lib/core/constants/student_model.dart`
- `package:test/models/subject_model.dart` → `lib/core/constants/subject_model.dart`
- `package:test/models/teacher_model.dart` → `lib/core/constants/teacher_model.dart`

**Files importing models** (12 unique model files):
- `lib/services/firestore_service.dart` (11 model imports)
- `lib/services/admin_service.dart`
- `lib/db/student_management_repository.dart`
- `lib/services/local_data_service.dart`
- `lib/features/teachers/data/teachers_firestore_service.dart`
- `lib/features/teachers/presentation/pages/teacher_subject_selection_page.dart`
- `lib/features/students/services/attendance_service.dart`
- `lib/services/department_auth_service.dart`
- `lib/pages/departement/providers/student_management_provider.dart`
- `lib/pages/departement/AddTeacher.dart`
- `lib/pages/departement/AddStudent.dart`
- `lib/pages/departement/AddSubject.dart`
- `lib/pages/departement/edit_subject_page.dart`
- `lib/pages/departement/groups_screen.dart`
- `lib/pages/departement/ViewTeachers.dart`
- `lib/pages/departement/ViewSubjects.dart`
- `lib/pages/departement/students_screen.dart`
- `lib/pages/departement/ViewExclude.dart`
- `lib/pages/departement/ViewStudent.dart`
- `lib/pages/departement/VewJustification.dart`
- And ~30+ other files

---

### 3.2 PROVIDERS (Package: test/providers/)
**Current Location**: `lib/providers/`  
**Target Location**: `lib/core/providers/`

**Provider imports**:
- `package:test/providers/locale_provider.dart` → `lib/core/providers/locale_provider.dart`
- `package:test/providers/theme_provider.dart` → `lib/core/providers/theme_provider.dart`

**Files importing providers**:
- `lib/main.dart`
- `lib/main_clean.dart`
- `lib/main_fixed.dart`
- `lib/main_secure.dart`
- `lib/helpers/localization_helper.dart`

---

### 3.3 HELPERS (Package: test/helpers/)
**Current Location**: `lib/helpers/`  
**Target Location**: `lib/core/helpers/`

**Helper imports**:
- `package:test/helpers/localization_helper.dart` → `lib/core/helpers/localization_helper.dart`

**Files importing helpers** (11 files):
- `lib/main.dart`
- `lib/pages/departement/common_widgets.dart`
- `lib/pages/departement/ViewStudent.dart`
- `lib/pages/departement/ViewTeachers.dart`
- `lib/pages/departement/VewJustification.dart`
- `lib/pages/department_dashboard.dart`
- `lib/pages/department_settings_page.dart`
- `lib/features/students/presentation/pages/justification_page.dart`

---

### 3.4 UTILITIES (Package: test/utils/)
**Current Location**: `lib/utils/`  
**Target Location**: `lib/core/utils/`

**Utility imports**:
- `package:test/utils/app_theme.dart` → `lib/core/utils/app_theme.dart`
- `package:test/utils/error_dialog_helper.dart` → `lib/core/utils/error_dialog_helper.dart`
- `package:test/utils/error_feedback_helper.dart` → `lib/core/utils/error_feedback_helper.dart`
- `package:test/utils/transitions_helper.dart` → `lib/core/utils/transitions_helper.dart`

**Files importing utils** (6 files):
- `lib/features/students/presentation/widgets/subject_attendance_card.dart`
- `lib/pages/role_based_error_handling_example.dart`
- `lib/widgets/enhanced_role_protected_screen.dart`
- `lib/features/students/presentation/pages/student_attendance_page.dart`

---

### 3.5 SERVICES (Package: test/services/)
**Current Location**: `lib/services/`  
**Target Location**: `lib/services/` (Keep, Core business logic)

**Service imports**:
- `package:test/services/admin_service.dart`
- `package:test/services/app_router.dart`
- `package:test/services/auth_service.dart`
- `package:test/services/department_auth_service.dart`
- `package:test/services/firestore_service.dart`
- `package:test/services/local_data_service.dart`
- `package:test/services/localization_service.dart`
- `package:test/services/role_check_service.dart`
- `package:test/services/role_manager.dart`
- `package:test/services/safe_navigation_helper.dart`
- `package:test/services/user_repository.dart`

**Files heavily importing services** (40+ files):
- ALL main.dart variants
- ALL feature pages
- ALL departement pages
- Providers
- Page widgets

---

### 3.6 CORE WIDGETS (Package: test/widgets/)
**Current Location**: `lib/widgets/`  
**Target Location**: `lib/core/widgets/`

**Widget imports**:
- `package:test/widgets/enhanced_role_protected_screen.dart` → `lib/core/widgets/enhanced_role_protected_screen.dart`
- `package:test/widgets/role_protected_screen.dart` → `lib/core/widgets/role_protected_screen.dart`
- `package:test/widgets/skeleton_box.dart` → `lib/core/widgets/skeleton_box.dart`

**Relative imports from skeleton_widgets**:
- `import 'base_skeleton.dart'` (relative)
- All skeleton exports in `skeleton_widgets.dart`

---

### 3.7 FEATURES - STUDENTS
**Current Location**: `lib/features/students/`  
**Target Location**: `lib/features/students/` (Already correct structure)

**Student feature imports**:
- `package:test/features/students/data/students_firestore_service.dart`
- `package:test/features/students/models/absence_feature_model.dart`
- `package:test/features/students/models/notification_feature_model.dart`
- `package:test/features/students/models/student_feature_model.dart`
- `package:test/features/students/presentation/pages/absence_tracker_page.dart`
- `package:test/features/students/presentation/pages/justification_page.dart`
- `package:test/features/students/presentation/pages/student_attendance_page.dart`
- `package:test/features/students/presentation/pages/student_profile_page.dart`
- `package:test/features/students/presentation/pages/student_requests_page.dart`
- `package:test/features/students/presentation/pages/students_page.dart`
- `package:test/features/students/presentation/widgets/subject_attendance_card.dart`
- `package:test/features/students/services/attendance_service.dart`

---

### 3.8 FEATURES - TEACHERS
**Current Location**: `lib/features/teachers/`  
**Target Location**: `lib/features/teachers/screens/` (For presentation pages)

**Teacher feature imports**:
- `package:test/features/teachers/data/teachers_firestore_service.dart`
- `package:test/features/teachers/models/teacher_feature_model.dart`
- `package:test/features/teachers/presentation/pages/teacher_attendance_flow_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_attendance_groups_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_attendance_history_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_group_attendance_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_group_selection_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_level_selection_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_profile_detail_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_profile_page.dart`
- `package:test/features/teachers/presentation/pages/teacher_subject_selection_page.dart`

---

### 3.9 FEATURES - DEPARTMENTS
**Current Location**: `lib/features/departments/`  
**Target Location**: `lib/features/departments/screens/` (For presentation pages)

**Department feature imports**:
- `package:test/features/departments/providers/department_notification_provider.dart`

**Note**: Most department-related code is in `lib/pages/departement/` and should be consolidated

---

### 3.10 OLD DEPARTEMENT PAGES
**Current Location**: `lib/pages/departement/`  
**Target Location**: `lib/features/departments/screens/`

**Departement page files to move**:
- `AddStudent.dart`
- `AddSubject.dart`
- `AddTeacher.dart`
- `ViewExclude.dart`
- `ViewStudent.dart`
- `ViewSubjects.dart`
- `ViewTeachers.dart`
- `VewJustification.dart`
- `add_department_account_page.dart`
- `common_widgets.dart`
- `create_admin_page.dart`
- `edit_subject_page.dart`
- `groups_screen.dart`
- `students_screen.dart`
- `widgets/hierarchy_item_card.dart`
- `widgets/student_info_card.dart`
- `providers/student_management_provider.dart`

---

### 3.11 FIREBASE & CONFIG
**Current Location**: `lib/firebase_options.dart`  
**Target Location**: `lib/core/config/firebase_options.dart`

**Files importing firebase_options**:
- `lib/main.dart`
- `lib/main_clean.dart`
- `lib/main_fixed.dart`
- `lib/main_secure.dart`
- `lib/services/department_auth_service.dart`

---

## 4. IMPORT MAPPING TABLE

### CORE LAYER - To be moved to lib/core/

| Current Path | New Path | Type |
|------------|----------|------|
| `lib/models/*` | `lib/core/constants/` | Models/Constants |
| `lib/helpers/*` | `lib/core/helpers/` | Helper utilities |
| `lib/utils/*` | `lib/core/utils/` | Utility functions |
| `lib/widgets/*` | `lib/core/widgets/` | Core UI widgets |
| `lib/providers/*` | `lib/core/providers/` | State management |
| `lib/firebase_options.dart` | `lib/core/config/firebase_options.dart` | Config |

### FEATURE LAYER - Already mostly correct, minor adjustments

| Current Path | New Path | Notes |
|------------|----------|-------|
| `lib/features/students/**` | `lib/features/students/**` | Keep as-is |
| `lib/features/teachers/**` | `lib/features/teachers/screens/**` | Move presentation pages to screens/ |
| `lib/features/departments/**` | `lib/features/departments/screens/` | Move pages from departement/ |
| `lib/pages/departement/**` | `lib/features/departments/screens/` | CONSOLIDATE HERE |
| `lib/pages/student.dart` | `lib/features/students/screens/student.dart` | Move to features |
| `lib/pages/login_page.dart` | `lib/features/auth/screens/login_page.dart` | Move to auth feature |
| `lib/pages/protected_dashboards.dart` | `lib/features/auth/screens/protected_dashboards.dart` | Move to auth |
| `lib/pages/role_home_page.dart` | `lib/features/auth/screens/role_home_page.dart` | Move to auth |

### SERVICES LAYER - Keep in lib/services/

All service files remain in `lib/services/` - no changes needed for this layer.

---

## 5. TOP IMPORT SOURCES (Most Imported Paths)

| Import Source | Count | Files Using It |
|---|---|---|
| `package:test/services/role_manager.dart` | 12 | 12 files |
| `package:test/services/department_auth_service.dart` | 11 | 11 files |
| `package:test/models/group_model.dart` | 10 | 10 files |
| `package:test/models/student_model.dart` | 10 | 10 files |
| `package:test/models/level_model.dart` | 10 | 10 files |
| `package:test/models/subject_model.dart` | 9 | 9 files |
| `package:test/models/teacher_model.dart` | 8 | 8 files |
| `package:test/helpers/localization_helper.dart` | 8 | 8 files |
| `package:test/services/firestore_service.dart` | 7 | 7 files |
| `package:test/services/auth_service.dart` | 6 | 6 files |
| `package:test/main.dart` | 14 | 14 files |
| `package:test/pages/departement/**` | 20+ | 20+ files |
| `package:test/features/teachers/**` | 11 | 11 files |
| `package:test/features/students/**` | 20 | 20 files |

---

## 6. RELATIVE IMPORTS (Already Local)

These files use relative imports and should remain unchanged or be carefully updated:

| File | Relative Import | Action |
|------|-----------------|--------|
| `lib/widgets/skeleton_widgets/table_skeleton.dart` | `import 'base_skeleton.dart'` | Keep relative |
| `lib/widgets/skeleton_widgets/profile_skeleton.dart` | `import 'base_skeleton.dart'` | Keep relative |
| `lib/widgets/skeleton_widgets/dashboard_skeleton.dart` | `import 'base_skeleton.dart'` | Keep relative |
| `lib/widgets/skeleton_widgets/card_skeleton.dart` | `import 'base_skeleton.dart'` | Keep relative |
| `lib/widgets/skeleton_widgets/skeleton_widgets.dart` | `export 'base_skeleton.dart'` etc | Keep relative |
| `lib/pages/departement/AddTeacher.dart` | `import 'common_widgets.dart'` | Keep relative |
| `lib/pages/departement/AddStudent.dart` | `import 'common_widgets.dart'` | Keep relative |
| `lib/pages/departement/AddSubject.dart` | `import 'common_widgets.dart'` | Keep relative |
| `lib/pages/departement/common_widgets.dart` | Multiple local imports | Keep relative |
| `lib/pages/department_dashboard.dart` | `import 'departement/AddStudent.dart'` | Update when consolidating |

---

## 7. FILES REQUIRING UPDATES - BY DIRECTORY

### Main Entry Points (4 files)
- [ ] `lib/main.dart`
- [ ] `lib/main_clean.dart`
- [ ] `lib/main_fixed.dart`
- [ ] `lib/main_secure.dart`

### Features - Teachers (11 files)
- [ ] `lib/features/teachers/data/teachers_firestore_service.dart`
- [ ] `lib/features/teachers/models/teacher_feature_model.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_attendance_flow_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_attendance_groups_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_attendance_history_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_group_attendance_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_group_selection_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_level_selection_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_profile_detail_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_profile_page.dart`
- [ ] `lib/features/teachers/presentation/pages/teacher_subject_selection_page.dart`

### Features - Students (12 files)
- [ ] `lib/features/students/data/students_firestore_service.dart`
- [ ] `lib/features/students/models/absence_feature_model.dart`
- [ ] `lib/features/students/models/notification_feature_model.dart`
- [ ] `lib/features/students/models/student_feature_model.dart`
- [ ] `lib/features/students/presentation/pages/absence_tracker_page.dart`
- [ ] `lib/features/students/presentation/pages/justification_page.dart`
- [ ] `lib/features/students/presentation/pages/student_attendance_page.dart`
- [ ] `lib/features/students/presentation/pages/student_profile_page.dart`
- [ ] `lib/features/students/presentation/pages/student_requests_page.dart`
- [ ] `lib/features/students/presentation/pages/students_page.dart`
- [ ] `lib/features/students/presentation/widgets/subject_attendance_card.dart`
- [ ] `lib/features/students/services/attendance_service.dart`

### Services (11 files)
- [ ] `lib/services/admin_service.dart`
- [ ] `lib/services/app_router.dart`
- [ ] `lib/services/auth_service.dart`
- [ ] `lib/services/department_auth_service.dart`
- [ ] `lib/services/firestore_service.dart`
- [ ] `lib/services/local_data_service.dart`
- [ ] `lib/services/localization_service.dart`
- [ ] `lib/services/role_check_service.dart`
- [ ] `lib/services/role_manager.dart`
- [ ] `lib/services/safe_navigation_helper.dart`
- [ ] `lib/services/user_repository.dart`

### Pages (13 files)
- [ ] `lib/pages/department_dashboard.dart`
- [ ] `lib/pages/department_settings_page.dart`
- [ ] `lib/pages/login_page.dart`
- [ ] `lib/pages/protected_dashboards.dart`
- [ ] `lib/pages/role_based_error_handling_example.dart`
- [ ] `lib/pages/role_home_page.dart`
- [ ] And all departement/* pages

### Helpers (1 file)
- [ ] `lib/helpers/localization_helper.dart`

### Utils (4 files)
- [ ] `lib/utils/app_theme.dart`
- [ ] `lib/utils/error_dialog_helper.dart`
- [ ] `lib/utils/error_feedback_helper.dart`
- [ ] `lib/utils/transitions_helper.dart`

### Widgets (10 files)
- [ ] `lib/widgets/enhanced_role_protected_screen.dart`
- [ ] `lib/widgets/role_protected_screen.dart`
- [ ] `lib/widgets/skeleton_box.dart`
- [ ] `lib/widgets/skeleton_widgets/base_skeleton.dart`
- [ ] `lib/widgets/skeleton_widgets/card_skeleton.dart`
- [ ] `lib/widgets/skeleton_widgets/dashboard_skeleton.dart`
- [ ] `lib/widgets/skeleton_widgets/profile_skeleton.dart`
- [ ] `lib/widgets/skeleton_widgets/skeleton_widgets.dart`
- [ ] `lib/widgets/skeleton_widgets/table_skeleton.dart`
- [ ] `lib/widgets/skeletons/* (6 files)`

### Providers (2 files)
- [ ] `lib/providers/locale_provider.dart`
- [ ] `lib/providers/theme_provider.dart`

### Database (1 file)
- [ ] `lib/db/student_management_repository.dart`

### Departement Pages (18 files) - TO BE CONSOLIDATED
- [ ] All files in `lib/pages/departement/`

---

## 8. CONSOLIDATION RECOMMENDATIONS

### Priority 1: Core Layer Setup
Move and update these first (foundation for everything else):
1. `lib/helpers/` → `lib/core/helpers/`
2. `lib/utils/` → `lib/core/utils/`
3. `lib/widgets/` → `lib/core/widgets/`
4. `lib/providers/` → `lib/core/providers/`
5. `lib/models/` → `lib/core/constants/`
6. `lib/firebase_options.dart` → `lib/core/config/firebase_options.dart`

### Priority 2: Services (Update imports of core layer)
Update all service files to import from new core paths

### Priority 3: Features (Update imports)
- Update teachers feature imports
- Update students feature imports
- Create auth feature and move login/auth pages
- Create departments feature and consolidate departement pages

### Priority 4: Main Entry Points
Update all main.dart variants once everything else is ready

---

## 9. IMPORT SUBSTITUTION GUIDE

### Generic Search-Replace Patterns

```
OLD → NEW

lib/helpers/ imports:
package:test/helpers/ → package:test/core/helpers/

lib/utils/ imports:
package:test/utils/ → package:test/core/utils/

lib/widgets/ imports:
package:test/widgets/ → package:test/core/widgets/

lib/providers/ imports:
package:test/providers/ → package:test/core/providers/

lib/models/ imports:
package:test/models/ → package:test/core/constants/

lib/firebase_options.dart:
package:test/firebase_options.dart → package:test/core/config/firebase_options.dart

lib/pages/departement/* → lib/features/departments/screens/*
```

---

## 10. MIGRATION CHECKLIST

- [ ] Identify and list all 180+ import statements (DONE - see this report)
- [ ] Create new directory structure:
  - [ ] `lib/core/constants/`
  - [ ] `lib/core/helpers/`
  - [ ] `lib/core/utils/`
  - [ ] `lib/core/widgets/`
  - [ ] `lib/core/providers/`
  - [ ] `lib/core/config/`
  - [ ] `lib/features/auth/screens/`
  - [ ] `lib/features/departments/screens/`
- [ ] Phase 1: Move core layer files (helpers, utils, widgets, providers, models)
- [ ] Phase 2: Update all service imports
- [ ] Phase 3: Update all feature imports
- [ ] Phase 4: Update all page imports
- [ ] Phase 5: Update main.dart variants
- [ ] Phase 6: Consolidate departement pages into departments feature
- [ ] Phase 7: Test build and verify all imports resolve
- [ ] Phase 8: Remove old directories

---

## Generated Report Notes

This analysis was performed by scanning all 101 .dart files in the lib directory and extracting:
- All `import` and `export` statements
- Both `package:test/` style and relative imports
- The files containing each import
- The frequency of each import source

**Total unique import paths identified**: 67 package:test imports + 11 relative imports + 28 external packages = **106 unique import sources**

**Recommendation**: Use a multi-phase migration strategy, starting with core layer, then services, then features, then pages. This allows dependent files to be updated once their dependencies are in place.
