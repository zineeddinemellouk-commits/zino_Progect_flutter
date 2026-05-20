# Import Updates By File - Quick Reference

## Format
```
FILE: relative/path/file.dart
CURRENT IMPORTS:
  - package:test/old/path → package:test/new/path
  - import 'relative/path' → keep as-is
```

---

## MAIN ENTRY POINTS

### lib/main.dart
CURRENT IMPORTS TO UPDATE:
- package:test/firebase_options.dart → package:test/core/config/firebase_options.dart
- package:test/providers/locale_provider.dart → package:test/core/providers/locale_provider.dart
- package:test/services/localization_service.dart (keep)
- All other service imports remain unchanged

### lib/main_clean.dart
CURRENT IMPORTS TO UPDATE:
- Same as main.dart

### lib/main_fixed.dart
CURRENT IMPORTS TO UPDATE:
- Same as main.dart

### lib/main_secure.dart
CURRENT IMPORTS TO UPDATE:
- Same as main.dart

---

## CORE LAYER FILES

### lib/helpers/localization_helper.dart
CURRENT IMPORTS TO UPDATE:
- package:test/providers/locale_provider.dart → package:test/core/providers/locale_provider.dart

### lib/utils/app_theme.dart
No internal imports - keep unchanged

### lib/utils/error_dialog_helper.dart
No internal imports - keep unchanged

### lib/utils/error_feedback_helper.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep - services stay in lib/services/)

### lib/utils/transitions_helper.dart
No internal imports - keep unchanged

### lib/widgets/role_protected_screen.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

### lib/widgets/enhanced_role_protected_screen.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)
- package:test/services/role_check_service.dart (keep)
- package:test/services/safe_navigation_helper.dart (keep)
- package:test/utils/error_feedback_helper.dart → package:test/core/utils/error_feedback_helper.dart

### lib/widgets/skeleton_box.dart
No internal imports - keep unchanged

### lib/widgets/skeleton_widgets/base_skeleton.dart
No internal imports - keep unchanged

### lib/widgets/skeleton_widgets/card_skeleton.dart
Relative imports only - keep unchanged

### lib/widgets/skeleton_widgets/dashboard_skeleton.dart
Relative imports only - keep unchanged

### lib/widgets/skeleton_widgets/profile_skeleton.dart
Relative imports only - keep unchanged

### lib/widgets/skeleton_widgets/table_skeleton.dart
Relative imports only - keep unchanged

### lib/widgets/skeleton_widgets/skeleton_widgets.dart
Relative exports only - keep unchanged

### lib/widgets/skeletons/form_skeleton.dart
CURRENT IMPORTS TO UPDATE:
- package:test/widgets/skeleton_box.dart → package:test/core/widgets/skeleton_box.dart

### lib/widgets/skeletons/teachers_list_skeleton.dart
CURRENT IMPORTS TO UPDATE:
- package:test/widgets/skeleton_box.dart → package:test/core/widgets/skeleton_box.dart

### lib/widgets/skeletons/students_list_skeleton.dart
CURRENT IMPORTS TO UPDATE:
- package:test/widgets/skeleton_box.dart → package:test/core/widgets/skeleton_box.dart

### lib/widgets/skeletons/drawer_skeleton.dart
CURRENT IMPORTS TO UPDATE:
- package:test/widgets/skeleton_box.dart → package:test/core/widgets/skeleton_box.dart

### lib/widgets/skeletons/attendance_skeleton.dart
CURRENT IMPORTS TO UPDATE:
- package:test/widgets/skeleton_box.dart → package:test/core/widgets/skeleton_box.dart

### lib/widgets/skeletons/subjects_list_skeleton.dart
No internal imports - keep unchanged

### lib/providers/locale_provider.dart
No internal imports - keep unchanged

### lib/providers/theme_provider.dart
No internal imports - keep unchanged

---

## SERVICE FILES (Keep location, but update imports they receive)

### lib/services/admin_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/admin_model.dart → package:test/core/constants/admin_model.dart

### lib/services/auth_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

### lib/services/department_auth_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/firebase_options.dart → package:test/core/config/firebase_options.dart
- package:test/models/app_user_profile.dart → package:test/core/constants/app_user_profile.dart

### lib/services/firestore_service.dart
CURRENT IMPORTS TO UPDATE (11 model files):
- package:test/models/absence_model.dart → package:test/core/constants/absence_model.dart
- package:test/models/class_model.dart → package:test/core/constants/class_model.dart
- package:test/models/exclusion_model.dart → package:test/core/constants/exclusion_model.dart
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/justification_model.dart → package:test/core/constants/justification_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart

### lib/services/localization_service.dart
No internal imports - keep unchanged

### lib/services/local_data_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart

### lib/services/role_check_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

### lib/services/role_manager.dart
No internal imports - keep unchanged

### lib/services/safe_navigation_helper.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

### lib/services/user_repository.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

### lib/services/app_router.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)

---

## DATABASE

### lib/db/student_management_repository.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart
- package:test/services/firestore_service.dart (keep)

---

## FEATURES - TEACHERS

### lib/features/teachers/models/teacher_feature_model.dart
No internal imports - keep unchanged

### lib/features/teachers/data/teachers_firestore_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/students/models/student_feature_model.dart (keep)
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart

### lib/features/teachers/presentation/pages/teacher_profile_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/department_auth_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_profile_detail_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/department_auth_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_attendance_groups_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/teachers/data/teachers_firestore_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_group_attendance_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/students/models/student_feature_model.dart (keep)
- package:test/features/teachers/data/teachers_firestore_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_subject_selection_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart

### lib/features/teachers/presentation/pages/teacher_level_selection_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/teachers/data/teachers_firestore_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_group_selection_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/teachers/data/teachers_firestore_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_attendance_history_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/teachers/data/teachers_firestore_service.dart (keep)

### lib/features/teachers/presentation/pages/teacher_attendance_flow_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/teachers/presentation/pages/teacher_subject_selection_page.dart (keep)

---

## FEATURES - STUDENTS

### lib/features/students/models/student_feature_model.dart
No internal imports - keep unchanged

### lib/features/students/models/absence_feature_model.dart
No internal imports - keep unchanged

### lib/features/students/models/notification_feature_model.dart
No internal imports - keep unchanged

### lib/features/students/services/attendance_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/absence_model.dart → package:test/core/constants/absence_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart

### lib/features/students/data/students_firestore_service.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/students/models/absence_feature_model.dart (keep)
- package:test/features/students/models/notification_feature_model.dart (keep)
- package:test/features/students/models/student_feature_model.dart (keep)

### lib/features/students/presentation/pages/students_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/department_auth_service.dart (keep)

### lib/features/students/presentation/pages/student_profile_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/department_auth_service.dart (keep)
- package:test/services/firestore_service.dart (keep)
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart

### lib/features/students/presentation/pages/student_attendance_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/utils/app_theme.dart → package:test/core/utils/app_theme.dart

### lib/features/students/presentation/pages/absence_tracker_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/students/data/students_firestore_service.dart (keep)

### lib/features/students/presentation/pages/justification_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

### lib/features/students/presentation/pages/student_requests_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/features/students/data/students_firestore_service.dart (keep)

### lib/features/students/presentation/widgets/subject_attendance_card.dart
CURRENT IMPORTS TO UPDATE:
- package:test/utils/app_theme.dart → package:test/core/utils/app_theme.dart

---

## FEATURES - DEPARTMENTS

### lib/features/departments/providers/department_notification_provider.dart
No internal imports - keep unchanged

---

## OLD PAGES (To be moved to features/departments/screens/)

### lib/pages/role_home_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/department_auth_service.dart (keep)

### lib/pages/login_page.dart
No internal imports - keep unchanged

### lib/pages/protected_dashboards.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)
- package:test/services/auth_service.dart (keep)
- package:test/widgets/role_protected_screen.dart → package:test/core/widgets/role_protected_screen.dart

### lib/pages/role_based_error_handling_example.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/role_manager.dart (keep)
- package:test/services/role_check_service.dart (keep)
- package:test/services/safe_navigation_helper.dart (keep)
- package:test/utils/error_feedback_helper.dart → package:test/core/utils/error_feedback_helper.dart
- package:test/widgets/enhanced_role_protected_screen.dart → package:test/core/widgets/enhanced_role_protected_screen.dart

### lib/pages/department_dashboard.dart
CURRENT IMPORTS TO UPDATE:
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart
- package:test/services/firestore_service.dart (keep)
- Relative import: departement/AddStudent.dart → update path after consolidation

### lib/pages/department_settings_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

---

## DEPARTEMENT PAGES (To be consolidated into lib/features/departments/screens/)

### lib/pages/departement/AddTeacher.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart

### lib/pages/departement/AddStudent.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart

### lib/pages/departement/AddSubject.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/class_model.dart → package:test/core/constants/class_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart

### lib/pages/departement/ViewTeachers.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

### lib/pages/departement/ViewSubjects.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/class_model.dart → package:test/core/constants/class_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart

### lib/pages/departement/ViewStudent.dart
CURRENT IMPORTS TO UPDATE:
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

### lib/pages/departement/ViewExclude.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/exclusion_model.dart → package:test/core/constants/exclusion_model.dart

### lib/pages/departement/VewJustification.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/justification_model.dart → package:test/core/constants/justification_model.dart
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

### lib/pages/departement/groups_screen.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart

### lib/pages/departement/students_screen.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart

### lib/pages/departement/common_widgets.dart
CURRENT IMPORTS TO UPDATE:
- package:test/helpers/localization_helper.dart → package:test/core/helpers/localization_helper.dart

### lib/pages/departement/add_department_account_page.dart
No package:test/models imports to update

### lib/pages/departement/create_admin_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/services/admin_service.dart (keep)

### lib/pages/departement/edit_subject_page.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart

### lib/pages/departement/providers/student_management_provider.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/class_model.dart → package:test/core/constants/class_model.dart
- package:test/models/exclusion_model.dart → package:test/core/constants/exclusion_model.dart
- package:test/models/group_model.dart → package:test/core/constants/group_model.dart
- package:test/models/justification_model.dart → package:test/core/constants/justification_model.dart
- package:test/models/level_model.dart → package:test/core/constants/level_model.dart
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart
- package:test/models/subject_model.dart → package:test/core/constants/subject_model.dart
- package:test/models/teacher_model.dart → package:test/core/constants/teacher_model.dart
- package:test/models/app_user_profile.dart → package:test/core/constants/app_user_profile.dart

### lib/pages/departement/widgets/student_info_card.dart
CURRENT IMPORTS TO UPDATE:
- package:test/models/student_model.dart → package:test/core/constants/student_model.dart

### lib/pages/departement/widgets/hierarchy_item_card.dart
No internal imports - keep unchanged

---

## SUMMARY OF CHANGES

### Files with NO changes needed (42 files):
- All external package imports remain unchanged
- All relative imports (skeleton widgets) remain unchanged
- Files with no internal imports

### Files requiring updates (50+ files):
- Model imports: need path updates to lib/core/constants/
- Helper imports: need path updates to lib/core/helpers/
- Utility imports: need path updates to lib/core/utils/
- Widget imports: need path updates to lib/core/widgets/
- Provider imports: need path updates to lib/core/providers/
- Firebase options: need path updates to lib/core/config/

### Total search-replace operations needed: ~80 import statement updates across 50+ files
