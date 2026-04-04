import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/services/firestore_service.dart';

class StudentManagementRepository {
  StudentManagementRepository({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  Stream<List<LevelModel>> watchLevels() {
    return _firestoreService.watchLevels();
  }

  Stream<List<GroupModel>> watchGroupsByLevel({required String levelId}) {
    return _firestoreService.watchGroupsByLevel(levelId);
  }

  Stream<List<StudentModel>> watchStudentsByGroup({required String groupId}) {
    return _firestoreService.watchStudentsByGroup(groupId);
  }

  Future<String> addGroup({required String name, required String levelId}) {
    return _firestoreService.addGroup(name: name, levelId: levelId);
  }

  Future<String> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    required String classId,
    required List<String> subjectIds,
    String? levelId,
  }) {
    return _firestoreService.addStudent(
      fullName: fullName,
      email: email,
      attendancePercentage: attendancePercentage,
      groupId: groupId,
      classId: classId,
      subjectIds: subjectIds,
      levelId: levelId,
    );
  }
}
