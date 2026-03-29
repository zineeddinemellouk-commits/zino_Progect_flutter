import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _levelsCollection =>
      _firestore.collection('levels');

  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection('students');

  Stream<List<LevelModel>> watchLevels() {
    return _levelsCollection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LevelModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<GroupModel>> watchGroupsByLevel(String levelId) {
    return _groupsCollection
        .where('levelId', isEqualTo: levelId)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
              .toList();
          groups.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return groups;
        });
  }

  Stream<List<StudentModel>> watchStudentsByGroup(String groupId) {
    return _studentsCollection
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.id, doc.data()))
              .toList();
          students.sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );
          return students;
        });
  }

  Future<void> addGroup({required String name, required String levelId}) async {
    await _groupsCollection.add(
      GroupModel(id: '', name: name.trim(), levelId: levelId).toMap(),
    );
  }

  Future<void> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    String? levelId,
  }) async {
    await _studentsCollection.add(
      StudentModel(
        id: '',
        fullName: fullName.trim(),
        email: email.trim(),
        attendancePercentage: attendancePercentage,
        groupId: groupId,
        levelId: levelId,
      ).toMap(),
    );
  }
}
