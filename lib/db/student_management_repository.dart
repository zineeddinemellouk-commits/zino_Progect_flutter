import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/local_data_service.dart';

class StudentManagementRepository {
  StudentManagementRepository({LocalDataService? localDataService})
    : _localDataService = localDataService ?? LocalDataService();

  final LocalDataService _localDataService;

  Stream<List<LevelModel>> watchLevels() {
    // Placeholder data source (database removed)
    return _localDataService.watchLevels();
  }

  Stream<List<GroupModel>> watchGroupsByLevel({required String levelId}) {
    // Placeholder data source (database removed)
    return _localDataService.watchGroupsByLevel(levelId);
  }

  Stream<List<StudentModel>> watchStudentsByGroup({required String groupId}) {
    // Placeholder data source (database removed)
    return _localDataService.watchStudentsByGroup(groupId);
  }

  Future<String> addGroup({required String name, required String levelId}) {
    // Placeholder write action (database removed)
    return _localDataService.addGroup(name: name, levelId: levelId);
  }

  Future<String> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) {
    // Placeholder write action (database removed)
    return _localDataService.addStudent(
      fullName: fullName,
      email: email,
      attendancePercentage: attendancePercentage,
      groupId: groupId,
      levelId: levelId,
    );
  }
}
