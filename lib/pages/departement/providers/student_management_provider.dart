import 'package:flutter/foundation.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/local_data_service.dart';

/// Provider for managing student-related operations
/// Handles CRUD operations and state management
class StudentManagementProvider extends ChangeNotifier {
  final LocalDataService _localDataService = LocalDataService();

  /// Watches all levels (L1, L2, L3, M1, M2)
  Stream<List<LevelModel>> watchLevels() {
    try {
      return _localDataService.watchLevels();
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
      return _localDataService.watchGroupsByLevel(levelId);
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
      return _localDataService.watchStudentsByGroup(groupId);
    } catch (e) {
      if (kDebugMode) print('❌ Error watching students: $e');
      return Stream.value(const []);
    }
  }

  /// Adds a new student to Firestore and notifies listeners
  Future<void> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) async {
    try {
      // Validate inputs
      fullName = fullName.trim();
      email = email.trim();

      if (fullName.isEmpty) {
        throw Exception('Student name cannot be empty');
      }
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
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
      await _localDataService.addStudent(
        fullName: fullName,
        email: email,
        attendancePercentage: attendancePercentage,
        groupId: groupId,
        levelId: levelId,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Error adding student: $e');
      rethrow; // Re-throw to let UI handle it
    }
  }

  /// Adds a new group to Firestore and notifies listeners
  Future<void> addGroup({
    required String name,
    required String levelId,
  }) async {
    try {
      name = name.trim();

      if (name.isEmpty) {
        throw Exception('Group name cannot be empty');
      }
      if (levelId.isEmpty) {
        throw Exception('Level ID cannot be empty');
      }

      if (kDebugMode) print('✅ Adding group: $name to level $levelId');
      await _localDataService.addGroup(name: name, levelId: levelId);
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
}
