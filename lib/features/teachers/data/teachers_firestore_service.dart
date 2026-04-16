import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/teachers/models/teacher_feature_model.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/subject_model.dart';

class TeacherDashboardData {
  const TeacherDashboardData({
    required this.teacher,
    required this.subjects,
    required this.levels,
    required this.groups,
    required this.students,
    required this.historyCount,
    required this.activeStudents,
    required this.attendanceRate,
    required this.attendanceBars,
  });

  final TeacherFeatureModel teacher;
  final List<SubjectModel> subjects;
  final List<LevelModel> levels;
  final List<GroupModel> groups;
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

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

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
      final groups = await _fetchGroupsForTeacher(teacher);
      final mergedLevelIds = <String>{
        ...teacher.levelIds,
        ...groups.map((group) => group.levelId),
      }.where((id) => id.trim().isNotEmpty).toList();

      final levels = await _fetchLevelsByIds(mergedLevelIds);
      final groupIds = groups.map((e) => e.id).toList();
      final subjectIds = subjects.map((e) => e.id).toList();

      final students = await _fetchStudents(
        groupIds: groupIds,
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
        levels: levels,
        groups: groups,
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

      final overviews = <TeacherGroupOverview>[];
      final countByGroup = <String, int>{};
      for (final student in students) {
        final groupId = student.groupId.trim();
        if (groupId.isEmpty) continue;
        countByGroup[groupId] = (countByGroup[groupId] ?? 0) + 1;
      }

      final levelsById = {
        for (final level in dashboard.levels) level.id: level,
      };

      for (final group in dashboard.groups) {
        final groupId = group.id;
        final studentCount = countByGroup[groupId] ?? 0;

        final levelId = group.levelId.trim();
        final levelName = (levelsById[levelId]?.name.trim().isNotEmpty ?? false)
            ? levelsById[levelId]!.name.trim()
            : (levelId.isEmpty ? '-' : levelId);

        overviews.add(
          TeacherGroupOverview(
            groupId: groupId,
            groupName: group.name.trim().isNotEmpty
                ? group.name.trim()
                : groupId,
            levelId: levelId,
            levelName: levelName,
            studentCount: studentCount,
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

  Stream<List<TeacherAttendanceHistoryItem>> watchGroupAttendanceHistory(
    String teacherId,
    String groupId,
  ) {
    final normalizedTeacherId = teacherId.trim();
    final normalizedGroupId = groupId.trim();
    if (normalizedTeacherId.isEmpty || normalizedGroupId.isEmpty) {
      return Stream.value(const <TeacherAttendanceHistoryItem>[]);
    }

    return _attendanceHistory
        .where('teacherId', isEqualTo: normalizedTeacherId)
        .where('groupId', isEqualTo: normalizedGroupId)
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

    final teacherSnap = await _teachers.doc(normalizedTeacherId).get();
    final teacherData = teacherSnap.data() ?? const <String, dynamic>{};
    final teacherName =
        (teacherData['fullName'] as String?)?.trim() ??
        (teacherData['email'] as String?)?.trim() ??
        'Unknown Teacher';

    String resolvedSubjectId = (subjectId ?? '').trim();
    String resolvedSubjectName = (subjectName ?? '').trim();
    if (resolvedSubjectId.isEmpty && teacherData['subjectIds'] is List) {
      final teacherSubjectIds = (teacherData['subjectIds'] as List<dynamic>)
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (teacherSubjectIds.isNotEmpty) {
        resolvedSubjectId = teacherSubjectIds.first;
      }
    }

    if (resolvedSubjectName.isEmpty && resolvedSubjectId.isNotEmpty) {
      final subjectSnap = await _subjects.doc(resolvedSubjectId).get();
      final subjectData = subjectSnap.data() ?? const <String, dynamic>{};
      resolvedSubjectName =
          (subjectData['name'] as String?)?.trim() ?? 'Unknown Subject';
    }

    if (resolvedSubjectName.isEmpty) {
      resolvedSubjectName = group.groupName;
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
    // Track absence IDs for notification linking
    final absenceIdByStudentId = <String, String>{};

    for (final doc in studentDocs) {
      final studentDocId = doc.id;
      final data = doc.data();
      
      // ✅ FIX: Use authUid from student document (Firebase Auth UID), not document ID
      final authUid = (data['authUid'] as String?) ?? studentDocId;
      
      final present = isPresentByStudentId[studentDocId] ?? true;

      final totalPresence = (data['totalPresence'] as num?)?.toInt() ?? 0;
      final totalAbsence = (data['totalAbsence'] as num?)?.toInt() ?? 0;
      final pendingAbsence = (data['pendingAbsence'] as num?)?.toInt() ?? 0;

      final nextPresence = present ? totalPresence + 1 : totalPresence;
      final nextAbsence = present ? totalAbsence : totalAbsence + 1;
      final nextPendingAbsence = present ? pendingAbsence : pendingAbsence + 1;

      final studentRef = _students.doc(studentDocId);
      batch.update(studentRef, {
        'totalPresence': nextPresence,
        'totalAbsence': nextAbsence,
        'pendingAbsence': nextPendingAbsence,
        'attendanceRate': _calcAttendanceRate(nextPresence, nextAbsence),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (present) {
        presentStudentIds.add(studentDocId);
      } else {
        absentStudentIds.add(studentDocId);
        final absenceRef = _absences.doc();
        absenceIdByStudentId[studentDocId] = absenceRef.id;
        batch.set(absenceRef, {
          'studentId': authUid,  // ✅ FIX: Use authUid (Firebase Auth UID) instead of document ID
          'teacherId': normalizedTeacherId,
          'teacherName': teacherName,
          'subjectId': resolvedSubjectId,
          'subjectName': resolvedSubjectName,
          'groupId': group.groupId,
          'levelId': group.levelId,
          'createdAt': Timestamp.fromDate(now),
          'deadlineAt': Timestamp.fromDate(deadlineAt),
          'status': 'pending',
          'courseCode': resolvedSubjectId.isEmpty
              ? group.groupId
              : resolvedSubjectId,
          'courseName': resolvedSubjectName,
        });
      }
    }

    final historyRef = _attendanceHistory.doc();
    batch.set(historyRef, {
      'teacherId': normalizedTeacherId,
      'teacherName': teacherName,
      'groupId': group.groupId,
      'groupName': group.groupName,
      'levelId': group.levelId,
      'levelName': group.levelName,
      'subjectId': resolvedSubjectId,
      'subjectName': resolvedSubjectName,
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

    // Create notifications for absent students with relatedAbsenceId link
    print('[TeachersFirestoreService] Creating ${absentStudentIds.length} notifications for absent students');
    for (final studentId in absentStudentIds) {
      try {
        final absenceId = absenceIdByStudentId[studentId];
        print('[TeachersFirestoreService] Creating notification for student=$studentId, absenceId=$absenceId, subject=$resolvedSubjectName');
        
        await _notifications.doc().set({
          'studentId': studentId,
          'type': 'absencerecorded',
          'title': 'New Absence Recorded',
          'message':
              'You were marked absent in $resolvedSubjectName by $teacherName',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          if (absenceId != null) 'relatedAbsenceId': absenceId,
        });
      } catch (e) {
        // Continue with other notifications even if one fails
        print('[TeachersFirestoreService] Failed to create notification for student=$studentId: $e');
      }
    }
    print('[TeachersFirestoreService] Attendance submitted: ${presentStudentIds.length} present, ${absentStudentIds.length} absent');
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

  Future<List<GroupModel>> _fetchGroupsForTeacher(
    TeacherFeatureModel teacher,
  ) async {
    final groupIds = <String>{
      ...teacher.groupIds,
    }.where((id) => id.trim().isNotEmpty).toList();

    if (groupIds.isEmpty) {
      return const <GroupModel>[];
    }

    final groupDocs = await _fetchDocsByIds(collection: _groups, ids: groupIds);

    final groups = groupDocs
        .map((doc) => GroupModel.fromMap(doc.id, doc.data()))
        .toList();
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  Future<List<LevelModel>> _fetchLevelsByIds(List<String> levelIds) async {
    final normalized = levelIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (normalized.isEmpty) {
      return const <LevelModel>[];
    }

    final levelDocs = await _fetchDocsByIds(
      collection: _levels,
      ids: normalized,
    );

    final levels = levelDocs
        .map((doc) => LevelModel.fromMap(doc.id, doc.data()))
        .toList();
    levels.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return levels;
  }

  Future<List<StudentFeatureModel>> _fetchStudents({
    required List<String> groupIds,
    required List<String> subjectIds,
  }) async {
    final studentsById = <String, StudentFeatureModel>{};

    if (groupIds.isNotEmpty) {
      final groupChunks = _chunkList(groupIds, 10);
      for (final chunk in groupChunks) {
        final snap = await _students.where('groupId', whereIn: chunk).get();
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
