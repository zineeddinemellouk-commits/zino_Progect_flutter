import 'package:flutter/material.dart';
import 'package:test/db/student_management_repository.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';

class StudentManagementProvider extends ChangeNotifier {
  StudentManagementProvider({StudentManagementRepository? repository})
    : _repository = repository ?? StudentManagementRepository();

  final StudentManagementRepository _repository;

  Stream<List<LevelModel>> watchLevels() {
    return _repository.watchLevels();
  }

  Stream<List<GroupModel>> watchGroupsByLevel(String levelId) {
    return _repository.watchGroupsByLevel(levelId);
  }

  Stream<List<StudentModel>> watchStudentsByGroup({required String groupId}) {
    return _repository.watchStudentsByGroup(groupId: groupId);
  }

  Future<void> addGroup({required String name, required String levelId}) {
    return _repository.addGroup(name: name, levelId: levelId);
  }

  Future<void> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) {
    return _repository.addStudent(
      fullName: fullName,
      email: email,
      attendancePercentage: attendancePercentage,
      groupId: groupId,
      levelId: levelId,
    );
  }
}
