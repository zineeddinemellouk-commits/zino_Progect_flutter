import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';

/// In-memory placeholder data source used after database removal.
class LocalDataService {
  final List<LevelModel> _levels = const [
    LevelModel(id: 'L1', name: 'L1'),
    LevelModel(id: 'L2', name: 'L2'),
    LevelModel(id: 'L3', name: 'L3'),
    LevelModel(id: 'M1', name: 'M1'),
    LevelModel(id: 'M2', name: 'M2'),
  ];

  final List<GroupModel> _groups = [];
  final List<StudentModel> _students = [];

  int _groupCounter = 0;
  int _studentCounter = 0;

  Stream<List<LevelModel>> watchLevels() {
    return Stream.value(List<LevelModel>.from(_levels));
  }

  Stream<List<GroupModel>> watchGroupsByLevel(String levelId) {
    final groups = _groups
        .where((group) => group.levelId == levelId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return Stream.value(groups);
  }

  Stream<List<StudentModel>> watchStudentsByGroup(String groupId) {
    final students = _students
        .where((student) => student.groupId == groupId)
        .toList()
      ..sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
    return Stream.value(students);
  }

  Future<String> addGroup({required String name, required String levelId}) async {
    _groupCounter += 1;
    final id = 'group_$_groupCounter';
    _groups.add(GroupModel(id: id, name: name.trim(), levelId: levelId));
    return id;
  }

  Future<String> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) async {
    _studentCounter += 1;
    final id = 'student_$_studentCounter';
    _students.add(
      StudentModel(
        id: id,
        fullName: fullName.trim(),
        email: email.trim(),
        attendancePercentage: attendancePercentage,
        groupId: groupId,
        classId: groupId,
        subjectIds: const [],
        levelId: levelId,
      ),
    );
    return id;
  }
}
