import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/teachers/models/teacher_feature_model.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/subject_model.dart';

class TeacherDashboardData {
  const TeacherDashboardData({
    required this.teacher,
    required this.subjects,
    required this.classes,
    required this.students,
    required this.historyCount,
    required this.activeStudents,
    required this.attendanceRate,
    required this.attendanceBars,
  });

  final TeacherFeatureModel teacher;
  final List<SubjectModel> subjects;
  final List<ClassModel> classes;
  final List<StudentFeatureModel> students;
  final int historyCount;
  final int activeStudents;
  final double attendanceRate;
  final List<double> attendanceBars;
}

class TeacherGroupOverview {
  const TeacherGroupOverview({
    required this.groupId,
    required this.groupName,
    required this.levelId,
    required this.levelName,
    required this.studentCount,
  });

  final String groupId;
  final String groupName;
  final String levelId;
  final String levelName;
  final int studentCount;
}

class TeacherAttendanceHistoryItem {
  const TeacherAttendanceHistoryItem({
    required this.id,
    required this.teacherId,
    required this.groupId,
    required this.groupName,
    required this.levelId,
    required this.levelName,
    required this.presentCount,
    required this.absentCount,
    required this.totalStudents,
    required this.createdAt,
  });

  final String id;
  final String teacherId;
  final String groupId;
  final String groupName;
  final String levelId;
  final String levelName;
  final int presentCount;
  final int absentCount;
  final int totalStudents;
  final DateTime createdAt;

  factory TeacherAttendanceHistoryItem.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawCreatedAt = map['createdAt'];
    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else {
      createdAt = DateTime.now();
    }

    return TeacherAttendanceHistoryItem(
      id: id,
      teacherId: (map['teacherId'] as String?)?.trim() ?? '',
      groupId: (map['groupId'] as String?)?.trim() ?? '',
      groupName: (map['groupName'] as String?)?.trim() ?? '-',
      levelId: (map['levelId'] as String?)?.trim() ?? '',
      levelName: (map['levelName'] as String?)?.trim() ?? '-',
      presentCount: (map['presentCount'] as num?)?.toInt() ?? 0,
      absentCount: (map['absentCount'] as num?)?.toInt() ?? 0,
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
    );
  }
}

class TeachersFirestoreService {
  TeachersFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _teachers =>
      _firestore.collection('teachers');

  CollectionReference<Map<String, dynamic>> get _subjects =>
      _firestore.collection('subjects');

  CollectionReference<Map<String, dynamic>> get _classes =>
      _firestore.collection('classes');

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _levels =>
      _firestore.collection('levels');

  CollectionReference<Map<String, dynamic>> get _students =>
      _firestore.collection('students');

  CollectionReference<Map<String, dynamic>> get _absences =>
      _firestore.collection('absences');

  CollectionReference<Map<String, dynamic>> get _attendanceHistory =>
      _firestore.collection('attendance_history');

  Stream<TeacherDashboardData?> watchTeacherDashboard({
    String? teacherId,
    String? teacherEmail,
  }) {
    return _watchTeacherDoc(
      teacherId: teacherId,
      teacherEmail: teacherEmail,
    ).asyncMap((doc) async {
      if (doc == null) {
        return null;
      }

      final teacher = TeacherFeatureModel.fromMap(doc.id, doc.data);
      final subjects = await _fetchSubjectsForTeacher(teacher);

      final mergedClassIds = <String>{
        ...teacher.classIds,
        ...subjects.expand((s) => s.classIds),
      }.where((id) => id.trim().isNotEmpty).toSet();

      final classes = await _fetchClassesByIds(mergedClassIds.toList());
      final classIds = classes.map((e) => e.id).toList();
      final subjectIds = subjects.map((e) => e.id).toList();

      final students = await _fetchStudents(
        classIds: classIds,
        subjectIds: subjectIds,
      );

      final totalPresence = students.fold<int>(
        0,
        (sum, item) => sum + item.totalPresence,
      );
      final totalAbsence = students.fold<int>(
        0,
        (sum, item) => sum + item.totalAbsence,
      );

      final attendanceRate = _calcAttendanceRate(totalPresence, totalAbsence);
      final activeStudents = students.where((s) => s.totalSessions > 0).length;
      final attendanceBars = _buildAttendanceBars(students);
      final historyCount = await _countAttendanceHistory(teacher.id);

      return TeacherDashboardData(
        teacher: teacher,
        subjects: subjects,
        classes: classes,
        students: students,
        historyCount: historyCount,
        activeStudents: activeStudents,
        attendanceRate: attendanceRate,
        attendanceBars: attendanceBars,
      );
    });
  }

  Stream<List<TeacherGroupOverview>> watchTeacherGroupsForSession({
    String? teacherId,
    String? teacherEmail,
  }) {
    return watchTeacherDashboard(
      teacherId: teacherId,
      teacherEmail: teacherEmail,
    ).asyncMap((dashboard) async {
      if (dashboard == null) {
        return const <TeacherGroupOverview>[];
      }

      final students = dashboard.students;
      if (students.isEmpty) {
        return const <TeacherGroupOverview>[];
      }

      final groupIds = students
          .map((e) => e.groupId.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final groupsById = <String, GroupModel>{};
      if (groupIds.isNotEmpty) {
        final groupDocs = await _fetchDocsByIds(
          collection: _groups,
          ids: groupIds,
        );
        for (final doc in groupDocs) {
          groupsById[doc.id] = GroupModel.fromMap(doc.id, doc.data());
        }
      }

      final levelIds = <String>{
        ...students.map((s) => s.levelId.trim()).where((id) => id.isNotEmpty),
        ...groupsById.values
            .map((g) => g.levelId.trim())
            .where((id) => id.isNotEmpty),
      }.toList();

      final levelsById = <String, LevelModel>{};
      if (levelIds.isNotEmpty) {
        final levelDocs = await _fetchDocsByIds(
          collection: _levels,
          ids: levelIds,
        );
        for (final doc in levelDocs) {
          levelsById[doc.id] = LevelModel.fromMap(doc.id, doc.data());
        }
      }

      final countByGroup = <String, int>{};
      for (final student in students) {
        final groupId = student.groupId.trim();
        if (groupId.isEmpty) continue;
        countByGroup[groupId] = (countByGroup[groupId] ?? 0) + 1;
      }

      final overviews = <TeacherGroupOverview>[];
      for (final entry in countByGroup.entries) {
        final groupId = entry.key;
        final group = groupsById[groupId];

        final groupName = (group?.name.trim().isNotEmpty ?? false)
            ? group!.name.trim()
            : groupId;

        final fallbackStudent = students.where(
          (s) => s.groupId.trim() == groupId,
        );
        final fallbackLevelId = fallbackStudent.isEmpty
            ? ''
            : fallbackStudent.first.levelId.trim();

        final levelId = (group?.levelId.trim().isNotEmpty ?? false)
            ? group!.levelId.trim()
            : fallbackLevelId;

        final levelName = (levelsById[levelId]?.name.trim().isNotEmpty ?? false)
            ? levelsById[levelId]!.name.trim()
            : (levelId.isEmpty ? '-' : levelId);

        overviews.add(
          TeacherGroupOverview(
            groupId: groupId,
            groupName: groupName,
            levelId: levelId,
            levelName: levelName,
            studentCount: entry.value,
          ),
        );
      }

      overviews.sort((a, b) {
        final levelCompare = a.levelName.toLowerCase().compareTo(
          b.levelName.toLowerCase(),
        );
        if (levelCompare != 0) return levelCompare;
        return a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase());
      });

      return overviews;
    });
  }

  Stream<List<StudentFeatureModel>> watchTeacherGroupStudents({
    String? teacherId,
    String? teacherEmail,
    required String groupId,
  }) {
    final normalizedGroupId = groupId.trim();
    if (normalizedGroupId.isEmpty) {
      return Stream.value(const <StudentFeatureModel>[]);
    }

    return watchTeacherDashboard(
      teacherId: teacherId,
      teacherEmail: teacherEmail,
    ).map((dashboard) {
      if (dashboard == null) {
        return const <StudentFeatureModel>[];
      }

      final students = dashboard.students
          .where((student) => student.groupId.trim() == normalizedGroupId)
          .toList();

      students.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );
      return students;
    });
  }

  Stream<List<TeacherAttendanceHistoryItem>> watchTeacherAttendanceHistory(
    String teacherId,
  ) {
    final normalizedTeacherId = teacherId.trim();
    if (normalizedTeacherId.isEmpty) {
      return Stream.value(const <TeacherAttendanceHistoryItem>[]);
    }

    return _attendanceHistory
        .where('teacherId', isEqualTo: normalizedTeacherId)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(
                (doc) =>
                    TeacherAttendanceHistoryItem.fromMap(doc.id, doc.data()),
              )
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> submitGroupAttendance({
    required String teacherId,
    required TeacherGroupOverview group,
    required Map<String, bool> isPresentByStudentId,
    String? subjectId,
    String? subjectName,
  }) async {
    final normalizedTeacherId = teacherId.trim();
    if (normalizedTeacherId.isEmpty) {
      throw Exception('Teacher ID is required');
    }

    final studentIds = isPresentByStudentId.keys
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (studentIds.isEmpty) {
      throw Exception('No students selected for attendance');
    }

    final studentDocs = await _fetchDocsByIds(
      collection: _students,
      ids: studentIds,
    );
    if (studentDocs.isEmpty) {
      throw Exception('Students could not be loaded');
    }

    final now = DateTime.now();
    final deadlineAt = now.add(const Duration(hours: 72));
    final batch = _firestore.batch();

    final presentStudentIds = <String>[];
    final absentStudentIds = <String>[];

    for (final doc in studentDocs) {
      final studentId = doc.id;
      final present = isPresentByStudentId[studentId] ?? true;
      final data = doc.data();

      final totalPresence = (data['totalPresence'] as num?)?.toInt() ?? 0;
      final totalAbsence = (data['totalAbsence'] as num?)?.toInt() ?? 0;
      final pendingAbsence = (data['pendingAbsence'] as num?)?.toInt() ?? 0;

      final nextPresence = present ? totalPresence + 1 : totalPresence;
      final nextAbsence = present ? totalAbsence : totalAbsence + 1;
      final nextPendingAbsence = present ? pendingAbsence : pendingAbsence + 1;

      final studentRef = _students.doc(studentId);
      batch.update(studentRef, {
        'totalPresence': nextPresence,
        'totalAbsence': nextAbsence,
        'pendingAbsence': nextPendingAbsence,
        'attendanceRate': _calcAttendanceRate(nextPresence, nextAbsence),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (present) {
        presentStudentIds.add(studentId);
      } else {
        absentStudentIds.add(studentId);
        final absenceRef = _absences.doc();
        batch.set(absenceRef, {
          'studentId': studentId,
          'teacherId': normalizedTeacherId,
          'groupId': group.groupId,
          'levelId': group.levelId,
          'createdAt': Timestamp.fromDate(now),
          'deadlineAt': Timestamp.fromDate(deadlineAt),
          'status': 'pending',
          'courseCode': (subjectId ?? '').trim().isEmpty
              ? group.groupId
              : subjectId!.trim(),
          'courseName': (subjectName ?? '').trim().isEmpty
              ? group.groupName
              : subjectName!.trim(),
        });
      }
    }

    final historyRef = _attendanceHistory.doc();
    batch.set(historyRef, {
      'teacherId': normalizedTeacherId,
      'groupId': group.groupId,
      'groupName': group.groupName,
      'levelId': group.levelId,
      'levelName': group.levelName,
      'presentStudentIds': presentStudentIds,
      'absentStudentIds': absentStudentIds,
      'presentCount': presentStudentIds.length,
      'absentCount': absentStudentIds.length,
      'totalStudents': presentStudentIds.length + absentStudentIds.length,
      'createdAt': FieldValue.serverTimestamp(),
      if ((subjectId ?? '').trim().isNotEmpty) 'subjectId': subjectId!.trim(),
      if ((subjectName ?? '').trim().isNotEmpty)
        'subjectName': subjectName!.trim(),
    });

    await batch.commit();
  }

  Future<List<SubjectModel>> _fetchSubjectsForTeacher(
    TeacherFeatureModel teacher,
  ) async {
    final byTeacherSnap = await _subjects
        .where('teacherId', isEqualTo: teacher.id)
        .get();

    final subjectMap = <String, SubjectModel>{
      for (final doc in byTeacherSnap.docs)
        doc.id: SubjectModel.fromMap(doc.id, doc.data()),
    };

    if (teacher.subjectIds.isNotEmpty) {
      final byIdDocs = await _fetchDocsByIds(
        collection: _subjects,
        ids: teacher.subjectIds,
      );
      for (final doc in byIdDocs) {
        subjectMap[doc.id] = SubjectModel.fromMap(doc.id, doc.data());
      }
    }

    final list = subjectMap.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<List<ClassModel>> _fetchClassesByIds(List<String> classIds) async {
    if (classIds.isEmpty) {
      return const <ClassModel>[];
    }

    final classDocs = await _fetchDocsByIds(
      collection: _classes,
      ids: classIds,
    );

    final classes = classDocs
        .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
        .toList();
    classes.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return classes;
  }

  Future<List<StudentFeatureModel>> _fetchStudents({
    required List<String> classIds,
    required List<String> subjectIds,
  }) async {
    final studentsById = <String, StudentFeatureModel>{};

    if (classIds.isNotEmpty) {
      final classChunks = _chunkList(classIds, 10);
      for (final chunk in classChunks) {
        final snap = await _students.where('classId', whereIn: chunk).get();
        for (final doc in snap.docs) {
          studentsById[doc.id] = StudentFeatureModel.fromMap(
            doc.id,
            doc.data(),
          );
        }
      }
    }

    if (subjectIds.isNotEmpty) {
      final subjectChunks = _chunkList(subjectIds, 10);
      for (final chunk in subjectChunks) {
        final snap = await _students
            .where('subjectIds', arrayContainsAny: chunk)
            .get();
        for (final doc in snap.docs) {
          studentsById[doc.id] = StudentFeatureModel.fromMap(
            doc.id,
            doc.data(),
          );
        }
      }
    }

    final students = studentsById.values.toList();
    students.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return students;
  }

  Future<int> _countAttendanceHistory(String teacherId) async {
    if (teacherId.trim().isEmpty) {
      return 0;
    }

    final snapshot = await _attendanceHistory
        .where('teacherId', isEqualTo: teacherId.trim())
        .get();
    return snapshot.docs.length;
  }

  Stream<_TeacherDocData?> _watchTeacherDoc({
    String? teacherId,
    String? teacherEmail,
  }) {
    final normalizedId = (teacherId ?? '').trim();
    final normalizedEmail = (teacherEmail ?? '').trim();

    if (normalizedId.isNotEmpty) {
      return _teachers.doc(normalizedId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) {
          return null;
        }

        final data = doc.data()!;
        return _TeacherDocData(id: doc.id, data: data);
      });
    }

    if (normalizedEmail.isNotEmpty) {
      return _teachers
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .snapshots()
          .map((snapshot) {
            if (snapshot.docs.isEmpty) {
              return null;
            }
            final doc = snapshot.docs.first;
            return _TeacherDocData(id: doc.id, data: doc.data());
          });
    }

    return Stream.value(null);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchDocsByIds({
    required CollectionReference<Map<String, dynamic>> collection,
    required List<String> ids,
  }) async {
    final normalizedIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedIds.isEmpty) {
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }

    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final chunks = _chunkList(normalizedIds, 10);
    for (final chunk in chunks) {
      final snap = await collection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      docs.addAll(snap.docs);
    }
    return docs;
  }

  List<List<T>> _chunkList<T>(List<T> items, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      chunks.add(items.sublist(i, end));
    }
    return chunks;
  }

  List<double> _buildAttendanceBars(List<StudentFeatureModel> students) {
    if (students.isEmpty) {
      return const <double>[0, 0, 0, 0, 0, 0];
    }

    final rates =
        students
            .map((s) => (s.attendanceRate * 100).clamp(0, 100).toDouble())
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final top = rates.take(6).toList();
    while (top.length < 6) {
      top.add(0);
    }
    return top;
  }

  double _calcAttendanceRate(int totalPresence, int totalAbsence) {
    final total = totalPresence + totalAbsence;
    if (total == 0) return 0;
    return totalPresence / total;
  }
}

class _TeacherDocData {
  const _TeacherDocData({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
