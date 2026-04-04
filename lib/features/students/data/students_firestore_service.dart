import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/students/models/absence_feature_model.dart';
import 'package:test/features/students/models/student_feature_model.dart';

class StudentsFirestoreService {
  StudentsFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  CollectionReference<Map<String, dynamic>> get _absences =>
      _firestore.collection('absences');

  CollectionReference<Map<String, dynamic>> get _levels =>
      _firestore.collection('levels');

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection('classes');

  Stream<List<StudentFeatureModel>> watchStudents() {
    return _students.orderBy('createdAt', descending: true).snapshots().map((
      s,
    ) {
      return s.docs
          .map((doc) => StudentFeatureModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<StudentFeatureModel>> watchStudentById(String id) {
    if (id.trim().isEmpty) {
      return Stream.value(const <StudentFeatureModel>[]);
    }
    return _students.doc(id.trim()).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return const <StudentFeatureModel>[];
      }
      return <StudentFeatureModel>[StudentFeatureModel.fromMap(doc.id, data)];
    });
  }

  Stream<List<StudentFeatureModel>> watchStudentByEmail(String email) {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      return Stream.value(const <StudentFeatureModel>[]);
    }
    return _students
        .where('email', isEqualTo: normalized)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StudentFeatureModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<AbsenceFeatureModel>> watchAbsencesByStudent(String studentId) {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return Stream.value(const <AbsenceFeatureModel>[]);
    }

    return _absences
        .where('studentId', isEqualTo: normalizedStudentId)
        .snapshots()
        .asyncMap((snapshot) async {
          final items = snapshot.docs
              .map((doc) => AbsenceFeatureModel.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final expired = items.where(
            (e) =>
                e.status == AbsenceStatus.pending &&
                DateTime.now().isAfter(e.deadlineAt),
          );

          for (final item in expired) {
            await rejectAbsence(absenceId: item.id, studentId: item.studentId);
          }

          if (expired.isNotEmpty) {
            final refreshed = await _absences
                .where('studentId', isEqualTo: normalizedStudentId)
                .get();
            final refreshedItems = refreshed.docs
                .map((doc) => AbsenceFeatureModel.fromMap(doc.id, doc.data()))
                .toList();
            refreshedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return refreshedItems;
          }

          return items;
        });
  }

  Stream<List<Map<String, String>>> watchLevels() {
    return _levels.orderBy('name').snapshots().map((s) {
      return s.docs
          .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '').toString()})
          .toList();
    });
  }

  Stream<List<Map<String, String>>> watchGroups() {
    return _groups.orderBy('name').snapshots().map((s) {
      return s.docs
          .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '').toString()})
          .toList();
    });
  }

  Stream<List<Map<String, String>>> watchClasses() {
    return _classes.orderBy('name').snapshots().map((s) {
      return s.docs
          .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '').toString()})
          .toList();
    });
  }

  Future<void> addStudent({
    required String fullName,
    required String email,
    required String levelId,
    required String groupId,
    required String classId,
    required int attendancePercentage,
  }) async {
    final doc = _students.doc();
    await doc.set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'levelId': levelId.trim(),
      'groupId': groupId.trim(),
      'classId': classId.trim(),
      'subjectIds': const <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'totalPresence': 0,
      'totalAbsence': 0,
      'justifiedAbsence': 0,
      'pendingAbsence': 0,
      'attendanceRate': 0.0,
      'attendancePercentage': attendancePercentage,
    });
  }

  Future<void> updateStudent({
    required String id,
    required String fullName,
    required String email,
    required String levelId,
    required String groupId,
    required String classId,
    required int attendancePercentage,
  }) {
    return _students.doc(id).update({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'levelId': levelId.trim(),
      'groupId': groupId.trim(),
      'classId': classId.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'attendancePercentage': attendancePercentage,
    });
  }

  Future<void> deleteStudent(String id) {
    return _students.doc(id).delete();
  }

  Future<void> markPresent({required String studentId}) async {
    final studentRef = _students.doc(studentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(studentRef);
      if (!snap.exists) throw Exception('Student not found');
      final data = snap.data() ?? const <String, dynamic>{};
      final totalPresence = (data['totalPresence'] as num?)?.toInt() ?? 0;
      final totalAbsence = (data['totalAbsence'] as num?)?.toInt() ?? 0;

      final updatedPresence = totalPresence + 1;
      final attendanceRate = _calcAttendanceRate(updatedPresence, totalAbsence);

      tx.update(studentRef, {
        'totalPresence': updatedPresence,
        'attendanceRate': attendanceRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markAbsent({
    required String studentId,
    String courseCode = '-',
    String courseName = 'Unspecified Course',
  }) async {
    final studentRef = _students.doc(studentId);
    final absenceRef = _absences.doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(studentRef);
      if (!snap.exists) throw Exception('Student not found');
      final data = snap.data() ?? const <String, dynamic>{};
      final totalPresence = (data['totalPresence'] as num?)?.toInt() ?? 0;
      final totalAbsence = (data['totalAbsence'] as num?)?.toInt() ?? 0;
      final pendingAbsence = (data['pendingAbsence'] as num?)?.toInt() ?? 0;

      final now = DateTime.now();
      final deadlineAt = now.add(const Duration(hours: 72));
      final updatedAbsence = totalAbsence + 1;
      final attendanceRate = _calcAttendanceRate(totalPresence, updatedAbsence);

      tx.set(absenceRef, {
        'studentId': studentId,
        'createdAt': Timestamp.fromDate(now),
        'deadlineAt': Timestamp.fromDate(deadlineAt),
        'status': 'pending',
        'courseCode': courseCode,
        'courseName': courseName,
      });

      tx.update(studentRef, {
        'totalAbsence': updatedAbsence,
        'pendingAbsence': pendingAbsence + 1,
        'attendanceRate': attendanceRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> submitAbsenceJustification({
    required String absenceId,
    required String studentId,
  }) async {
    final absenceRef = _absences.doc(absenceId);
    final studentRef = _students.doc(studentId);

    await _firestore.runTransaction((tx) async {
      final absenceSnap = await tx.get(absenceRef);
      final studentSnap = await tx.get(studentRef);

      if (!absenceSnap.exists || !studentSnap.exists) {
        throw Exception('Record not found');
      }

      final absenceData = absenceSnap.data() ?? const <String, dynamic>{};
      final studentData = studentSnap.data() ?? const <String, dynamic>{};

      final status =
          (absenceData['status'] as String?)?.toLowerCase() ?? 'pending';
      final deadlineRaw = absenceData['deadlineAt'];
      final deadlineAt = deadlineRaw is Timestamp
          ? deadlineRaw.toDate()
          : DateTime.now();

      if (status != 'pending') {
        throw Exception('Absence is no longer pending.');
      }

      if (DateTime.now().isAfter(deadlineAt)) {
        throw Exception(
          'Deadline expired. Justification is no longer allowed.',
        );
      }

      final pending = (studentData['pendingAbsence'] as num?)?.toInt() ?? 0;
      final justified = (studentData['justifiedAbsence'] as num?)?.toInt() ?? 0;

      tx.update(absenceRef, {
        'status': 'justified',
        'justifiedAt': FieldValue.serverTimestamp(),
      });

      tx.update(studentRef, {
        'pendingAbsence': pending > 0 ? pending - 1 : 0,
        'justifiedAbsence': justified + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectAbsence({
    required String absenceId,
    required String studentId,
  }) async {
    final absenceRef = _absences.doc(absenceId);
    final studentRef = _students.doc(studentId);

    await _firestore.runTransaction((tx) async {
      final absenceSnap = await tx.get(absenceRef);
      final studentSnap = await tx.get(studentRef);

      if (!absenceSnap.exists || !studentSnap.exists) {
        return;
      }

      final absenceData = absenceSnap.data() ?? const <String, dynamic>{};
      final status =
          (absenceData['status'] as String?)?.toLowerCase() ?? 'pending';
      if (status != 'pending') return;

      final studentData = studentSnap.data() ?? const <String, dynamic>{};
      final pending = (studentData['pendingAbsence'] as num?)?.toInt() ?? 0;

      tx.update(absenceRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      tx.update(studentRef, {
        'pendingAbsence': pending > 0 ? pending - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  double _calcAttendanceRate(int totalPresence, int totalAbsence) {
    final total = totalPresence + totalAbsence;
    if (total == 0) return 0;
    return totalPresence / total;
  }
}
