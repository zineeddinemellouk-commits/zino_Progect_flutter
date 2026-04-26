import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/models/absence_model.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/justification_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/student_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';

class AttendanceOverviewStats {
  const AttendanceOverviewStats({
    required this.totalStudents,
    required this.averageAttendanceRate,
    required this.averageAttendancePoints,
  });

  final int totalStudents;
  final double averageAttendanceRate;
  final double averageAttendancePoints;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _levels =>
      _firestore.collection('levels');
  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');
  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');
  CollectionReference<Map<String, dynamic>> get _teachers =>
      _firestore.collection('teachers');
  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('subjects');
  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection('classes');
  CollectionReference<Map<String, dynamic>> get _justifications =>
      _firestore.collection('justifications');
  CollectionReference<Map<String, dynamic>> get _absences =>
      _firestore.collection('absences');

  /// Aggregated attendance data for department dashboards.
  ///
  /// The overall attendance rate is calculated from all student documents in
  /// Firestore with this fallback order per student:
  /// 1) totalPresence/totalAbsence (live attendance session data)
  /// 2) attendanceRate (stored as 0..1 or 0..100)
  /// 3) attendancePercentage (legacy field)
  Stream<AttendanceOverviewStats> watchAttendanceOverview() {
    return _students.snapshots().map((snapshot) {
      final docs = snapshot.docs;
      if (docs.isEmpty) {
        return const AttendanceOverviewStats(
          totalStudents: 0,
          averageAttendanceRate: 0,
          averageAttendancePoints: 0,
        );
      }

      final totalAttendancePoints = docs.fold<double>(
        0,
        (sum, doc) => sum + _resolveStudentAttendancePercentage(doc.data()),
      );

      final averageAttendancePoints = totalAttendancePoints / docs.length;
      final normalizedAverage = _normalizeAttendanceRate(averageAttendancePoints);

      return AttendanceOverviewStats(
        totalStudents: docs.length,
        averageAttendanceRate: normalizedAverage,
        averageAttendancePoints: normalizedAverage,
      );
    });
  }

  double _resolveStudentAttendancePercentage(Map<String, dynamic> data) {
    final totalPresence = (data['totalPresence'] as num?)?.toDouble() ?? 0;
    final totalAbsence = (data['totalAbsence'] as num?)?.toDouble() ?? 0;
    final totalSessions = totalPresence + totalAbsence;

    if (totalSessions > 0) {
      return _normalizeAttendanceRate((totalPresence / totalSessions) * 100);
    }

    final rawAttendanceRate = (data['attendanceRate'] as num?)?.toDouble();
    if (rawAttendanceRate != null) {
      final normalizedRate = rawAttendanceRate <= 1
          ? rawAttendanceRate * 100
          : rawAttendanceRate;
      return _normalizeAttendanceRate(normalizedRate);
    }

    final attendancePercentage =
        (data['attendancePercentage'] as num?)?.toDouble() ?? 0;
    return _normalizeAttendanceRate(attendancePercentage);
  }

  double _normalizeAttendanceRate(double attendancePoints) {
    if (attendancePoints.isNaN || attendancePoints.isInfinite) {
      return 0;
    }
    return attendancePoints.clamp(0, 100).toDouble();
  }

  Future<void> ensureBaseData() async {
    final levelsSnapshot = await _levels.limit(1).get();
    if (levelsSnapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    final defaultLevels = <LevelModel>[
      const LevelModel(id: 'L1', name: 'L1'),
      const LevelModel(id: 'L2', name: 'L2'),
      const LevelModel(id: 'L3', name: 'L3'),
      const LevelModel(id: 'M1', name: 'M1'),
      const LevelModel(id: 'M2', name: 'M2'),
    ];

    for (final level in defaultLevels) {
      batch.set(_levels.doc(level.id), level.toMap());
    }

    final defaultClasses = <ClassModel>[
      const ClassModel(id: 'class_l1_a', name: 'L1 - A', levelId: 'L1'),
      const ClassModel(id: 'class_l2_a', name: 'L2 - A', levelId: 'L2'),
      const ClassModel(id: 'class_l3_a', name: 'L3 - A', levelId: 'L3'),
      const ClassModel(id: 'class_m1_a', name: 'M1 - A', levelId: 'M1'),
      const ClassModel(id: 'class_m2_a', name: 'M2 - A', levelId: 'M2'),
    ];

    for (final c in defaultClasses) {
      batch.set(_classes.doc(c.id), c.toMap());
    }

    await batch.commit();
  }

  Stream<List<LevelModel>> watchLevels() {
    return _levels
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LevelModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<GroupModel>> watchGroupsByLevel(String levelId) {
    return _groups.where('levelId', isEqualTo: levelId).snapshots().map((
      snapshot,
    ) {
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
    return _students.where('groupId', isEqualTo: groupId).snapshots().map((
      snapshot,
    ) {
      final students = snapshot.docs
          .map((doc) => StudentModel.fromMap(doc.id, doc.data()))
          .toList();
      students.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return students;
    });
  }

  Stream<List<StudentModel>> watchAllStudents() {
    return _students
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  double calculateOverallAttendanceRate(List<StudentModel> students) {
    if (students.isEmpty) {
      return 0;
    }

    final totalAttendancePoints = students.fold<int>(
      0,
      (sum, student) => sum + student.attendancePercentage,
    );
    return _normalizeAttendanceRate(totalAttendancePoints / students.length);
  }

  Future<String> addGroup({
    required String name,
    required String levelId,
  }) async {
    final doc = _groups.doc();
    final group = GroupModel(id: doc.id, name: name, levelId: levelId);
    await doc.set({
      ...group.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateGroup({
    required String id,
    required String name,
    required String levelId,
  }) {
    return _groups.doc(id).update({'name': name, 'levelId': levelId});
  }

  Future<void> deleteGroup(String id) => _groups.doc(id).delete();

  Future<String> addStudent({
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    required String classId,
    required List<String> subjectIds,
    String? levelId,
    String? authUid,
  }) async {
    final doc = _students.doc();
    final student = StudentModel(
      id: doc.id,
      fullName: fullName,
      email: email,
      attendancePercentage: attendancePercentage,
      groupId: groupId,
      classId: classId,
      subjectIds: subjectIds,
      levelId: levelId,
    );

    final data = <String, dynamic>{
      ...student.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (authUid != null && authUid.isNotEmpty) {
      data['authUid'] = authUid;
    }
    await doc.set(data);
    return doc.id;
  }

  Future<void> updateStudent({
    required String id,
    required String fullName,
    required String email,
    required int attendancePercentage,
    required String groupId,
    required String classId,
    required List<String> subjectIds,
    String? levelId,
  }) {
    return _students.doc(id).update({
      'fullName': fullName,
      'email': email,
      'attendancePercentage': attendancePercentage,
      'groupId': groupId,
      'classId': classId,
      'subjectIds': subjectIds,
      'levelId': levelId,
    });
  }

  Future<void> deleteStudent(String id) => _students.doc(id).delete();

  Stream<List<TeacherModel>> watchTeachers() {
    return _teachers
        .orderBy('fullName')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TeacherModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> addTeacher({
    required String fullName,
    required String email,
    required List<String> subjectIds,
    required List<String> levelIds,
    required List<String> groupIds,
    String? authUid,
  }) async {
    final doc = _teachers.doc();
    final teacher = TeacherModel(
      id: doc.id,
      fullName: fullName,
      email: email,
      subjectIds: subjectIds,
      levelIds: levelIds,
      groupIds: groupIds,
    );
    final data = <String, dynamic>{
      ...teacher.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (authUid != null && authUid.isNotEmpty) {
      data['authUid'] = authUid;
    }
    await doc.set(data);
    return doc.id;
  }

  Future<void> updateTeacher({
    required String id,
    required String fullName,
    required String email,
    required List<String> subjectIds,
    required List<String> levelIds,
    required List<String> groupIds,
  }) {
    return _teachers.doc(id).update({
      'fullName': fullName,
      'email': email,
      'subjectIds': subjectIds,
      'levelIds': levelIds,
      'groupIds': groupIds,
    });
  }

  Future<void> deleteTeacher(String id) => _teachers.doc(id).delete();

  Stream<List<SubjectModel>> watchSubjects() {
    return _subjects
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> addSubject({
    required String name,
    required String teacherId,
    required List<String> classIds,
  }) async {
    final doc = _subjects.doc();
    final subject = SubjectModel(
      id: doc.id,
      name: name,
      teacherId: teacherId,
      classIds: classIds,
    );
    await doc.set({
      ...subject.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateSubject({
    required String id,
    required String name,
    required String teacherId,
    required List<String> classIds,
  }) {
    return _subjects.doc(id).update({
      'name': name,
      'teacherId': teacherId,
      'classIds': classIds,
    });
  }

  Future<void> deleteSubject(String id) => _subjects.doc(id).delete();

  Stream<List<ClassModel>> watchClasses() {
    return _classes
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ClassModel>> watchClassesByLevel(String levelId) {
    return _classes.where('levelId', isEqualTo: levelId).snapshots().map((
      snapshot,
    ) {
      final classes = snapshot.docs
          .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
          .toList();
      classes.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return classes;
    });
  }

  Future<String> addClass({
    required String name,
    required String levelId,
  }) async {
    final doc = _classes.doc();
    final item = ClassModel(id: doc.id, name: name, levelId: levelId);
    await doc.set({...item.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    return doc.id;
  }

  Stream<List<JustificationModel>> watchJustifications() {
    return _justifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JustificationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> addJustification(JustificationModel justification) async {
    final doc = _justifications.doc();
    await doc.set({
      ...justification.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateJustificationStatus({
    required String id,
    required String status,
    String? refusalReason,
  }) {
    return _justifications.doc(id).update({
      'status': status,
      'refusalReason': refusalReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteJustification(String id) =>
      _justifications.doc(id).delete();

  /// Watches absences for a given student.
  Stream<List<AbsenceModel>> watchAbsencesByStudent(String studentId) {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return Stream.value(const <AbsenceModel>[]);
    }

    return _absences
        .where('studentId', isEqualTo: normalizedStudentId)
        .snapshots()
        .map((snapshot) {
          final absences = snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.id, doc.data()))
              .toList();
          absences.sort((a, b) => b.absenceDate.compareTo(a.absenceDate));
          return absences;
        });
  }

  /// Watches all absences (for admin view).
  Stream<List<AbsenceModel>> watchAllAbsences() {
    return _absences
        .orderBy('absenceDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Creates a new absence record.
  Future<String> addAbsence(AbsenceModel absence) async {
    final doc = _absences.doc();
    await doc.set({
      ...absence.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Updates an absence status.
  Future<void> updateAbsenceStatus({
    required String id,
    required String status,
    String? justificationId,
  }) {
    return _absences.doc(id).update({
      'status': status,
      if (justificationId != null && justificationId.isNotEmpty)
        'justificationId': justificationId,
      if (status == 'justified') 'justifiedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an absence record.
  Future<void> deleteAbsence(String id) => _absences.doc(id).delete();
}
