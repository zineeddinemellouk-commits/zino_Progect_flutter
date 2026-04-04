import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/justification_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/models/app_user_profile.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/services/firestore_service.dart';

/// Provider for managing student-related operations
/// Handles CRUD operations and state management
class StudentManagementProvider extends ChangeNotifier {
  StudentManagementProvider();

  final FirestoreService _firestoreService = FirestoreService();
  final DepartmentAuthService _authService = DepartmentAuthService();

  /// Best-effort base data seeding. This should never crash the app when
  /// Firestore rules deny writes.
  Future<void> initializeBaseData() async {
    try {
      await _firestoreService.ensureBaseData();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore base-data init skipped: ${e.code} ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Unexpected base-data init error: $e');
      }
    }
  }

  /// Watches all levels (L1, L2, L3, M1, M2)
  Stream<List<LevelModel>> watchLevels() {
    try {
      return _firestoreService.watchLevels();
    } catch (e) {
      if (kDebugMode) print('❌ Error watching levels: $e');
      return Stream.value(const []);
    }
  }

  /// Watches groups for a specific level (requires levelId parameter)
  Stream<List<GroupModel>> watchGroupsByLevel({required String levelId}) {
    try {
      if (levelId.isEmpty) {
        return Stream.value(const []);
      }
      return _firestoreService.watchGroupsByLevel(levelId);
    } catch (e) {
      if (kDebugMode) print('❌ Error watching groups: $e');
      return Stream.value(const []);
    }
  }

  /// Watches students in a specific group (requires groupId parameter)
  Stream<List<StudentModel>> watchStudentsByGroup({required String groupId}) {
    try {
      if (groupId.isEmpty) {
        return Stream.value(const []);
      }
      return _firestoreService.watchStudentsByGroup(groupId);
    } catch (e) {
      if (kDebugMode) print('❌ Error watching students: $e');
      return Stream.value(const []);
    }
  }

  /// Adds a new student to local placeholder state and notifies listeners
  Future<void> addStudent({
    required String fullName,
    required String email,
    required String password,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) async {
    try {
      // Validate inputs
      fullName = fullName.trim();
      email = email.trim();
      password = password.trim();

      if (fullName.isEmpty) {
        throw Exception('Student name cannot be empty');
      }
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (attendancePercentage < 0 || attendancePercentage > 100) {
        throw Exception('Attendance must be between 0 and 100');
      }
      if (groupId.isEmpty) {
        throw Exception('Group ID cannot be empty');
      }

      if (kDebugMode) print('✅ Adding student: $fullName');
      final authUid = await _authService.createManagedAccount(
        email: email,
        password: password,
      );

      String? studentId;
      try {
        studentId = await _firestoreService.addStudent(
          fullName: fullName,
          email: email,
          attendancePercentage: attendancePercentage,
          groupId: groupId,
          classId: groupId,
          subjectIds: const [],
          levelId: levelId,
          authUid: authUid,
        );

        await _authService.saveUserProfile(
          AppUserProfile(
            uid: authUid,
            email: email,
            role: 'Student',
            displayName: fullName,
            linkedCollection: 'students',
            linkedDocumentId: studentId,
          ),
        );

        await _authService.signOutManagedAccount();
      } catch (e) {
        if (studentId != null) {
          await _firestoreService.deleteStudent(studentId);
        }
        await _authService.deletePendingManagedAccount();
        rethrow;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Error adding student: $e');
      rethrow; // Re-throw to let UI handle it
    }
  }

  /// Adds a new group to local placeholder state and notifies listeners
  Future<void> addGroup({required String name, required String levelId}) async {
    try {
      name = name.trim();

      if (name.isEmpty) {
        throw Exception('Group name cannot be empty');
      }
      if (levelId.isEmpty) {
        throw Exception('Level ID cannot be empty');
      }

      if (kDebugMode) print('✅ Adding group: $name to level $levelId');
      await _firestoreService.addGroup(name: name, levelId: levelId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Error adding group: $e');
      rethrow;
    }
  }

  /// Validates email format (RFC 5322 compliant)
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  Stream<List<StudentModel>> watchAllStudents() {
    return _firestoreService.watchAllStudents();
  }

  Stream<List<TeacherModel>> watchTeachers() {
    return _firestoreService.watchTeachers();
  }

  Stream<List<SubjectModel>> watchSubjects() {
    return _firestoreService.watchSubjects();
  }

  Stream<List<ClassModel>> watchClasses() {
    return _firestoreService.watchClasses();
  }

  Stream<List<JustificationModel>> watchJustifications() {
    return _firestoreService.watchJustifications();
  }

  Future<void> addTeacher({
    required String fullName,
    required String email,
    required String password,
    required List<String> subjectIds,
  }) async {
    fullName = fullName.trim();
    email = email.trim();
    password = password.trim();

    if (fullName.isEmpty) throw Exception('Teacher name cannot be empty');
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (!_isValidEmail(email)) throw Exception('Invalid email format');

    final authUid = await _authService.createManagedAccount(
      email: email,
      password: password,
    );

    String? teacherId;
    try {
      teacherId = await _firestoreService.addTeacher(
        fullName: fullName,
        email: email,
        subjectIds: subjectIds,
        authUid: authUid,
      );

      await _authService.saveUserProfile(
        AppUserProfile(
          uid: authUid,
          email: email,
          role: 'Teacher',
          displayName: fullName,
          linkedCollection: 'teachers',
          linkedDocumentId: teacherId,
        ),
      );

      await _authService.signOutManagedAccount();
    } catch (e) {
      if (teacherId != null) {
        await _firestoreService.deleteTeacher(teacherId);
      }
      await _authService.deletePendingManagedAccount();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> addSubject({
    required String name,
    required String teacherId,
    required List<String> classIds,
  }) async {
    name = name.trim();
    teacherId = teacherId.trim();

    if (name.isEmpty) throw Exception('Subject name cannot be empty');
    if (classIds.isEmpty) throw Exception('Select at least one class');

    await _firestoreService.addSubject(
      name: name,
      teacherId: teacherId,
      classIds: classIds,
    );
    notifyListeners();
  }

  Future<void> updateJustificationStatus({
    required String id,
    required String status,
    String? refusalReason,
  }) async {
    await _firestoreService.updateJustificationStatus(
      id: id,
      status: status,
      refusalReason: refusalReason,
    );
    notifyListeners();
  }
}
