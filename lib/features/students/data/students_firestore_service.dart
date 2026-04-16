import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:test/features/students/models/absence_feature_model.dart';
import 'package:test/features/students/models/notification_feature_model.dart';
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

  CollectionReference<Map<String, dynamic>> get _justifications =>
      _firestore.collection('justifications');

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

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
    print('[DEBUG] watchAbsencesByStudent called with: rawId="$studentId", normalized="$normalizedStudentId", length=${normalizedStudentId.length}');
    
    if (normalizedStudentId.isEmpty) {
      print('[DEBUG] studentId is empty, returning empty stream');
      return Stream.value(const <AbsenceFeatureModel>[]);
    }

    return _absences
        .where('studentId', isEqualTo: normalizedStudentId)
        .snapshots()
        .asyncMap((snapshot) async {
          print('[StudentsFirestoreService] watchAbsencesByStudent: studentId=$normalizedStudentId, docCount=${snapshot.docs.length}');
          
          if (snapshot.docs.isEmpty) {
            print('[DEBUG] ⚠️ NO DOCUMENTS FOUND for studentId=$normalizedStudentId');
            print('[DEBUG] Attempting to fetch ALL absences to check if they exist...');
            try {
              final allAbsences = await _absences.get();
              print('[DEBUG] Total absences in collection: ${allAbsences.docs.length}');
              for (final doc in allAbsences.docs.take(5)) {
                final docStudentId = doc.data()['studentId'] ?? 'null';
                print('[DEBUG]   Doc: ${doc.id}, studentId="$docStudentId" (matches=${"$docStudentId" == normalizedStudentId})');
              }
            } catch (e) {
              print('[DEBUG] Error fetching all absences: $e');
            }
          }
          
          final items = snapshot.docs
              .map((doc) => AbsenceFeatureModel.fromMap(doc.id, doc.data()))
              .toList();
          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          for (final item in items) {
            print('[StudentsFirestoreService] Absence: id=${item.id}, subject=${item.subjectName}, status=${item.status}, deadline=${item.deadlineAt}');
          }

          final expired = items.where(
            (e) =>
                e.status == AbsenceStatus.pending &&
                DateTime.now().isAfter(e.deadlineAt),
          );

          if (expired.isNotEmpty) {
            print('[StudentsFirestoreService] Found ${expired.length} expired absence(s), marking as rejected');
          }

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
            await _syncStudentAbsenceCounters(
              normalizedStudentId,
              refreshedItems,
            );
            return refreshedItems;
          }

          await _syncStudentAbsenceCounters(normalizedStudentId, items);
          return items;
        });
  }

  /// DEBUG METHOD: Fetch all absences without filter to diagnose issues
  Future<void> debugPrintAllAbsences() async {
    try {
      print('[DEBUG] ===== FIRESTORE ABSENCES COLLECTION DEBUG =====');
      final snapshot = await _absences.get();
      print('[DEBUG] Total absence documents: ${snapshot.docs.length}');
      
      // Print first 10 documents
      for (int i = 0; i < snapshot.docs.length && i < 10; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        print('[DEBUG] Document $i: id=${doc.id}');
        print('[DEBUG]   studentId: "${data['studentId']}"');
        print('[DEBUG]   teacherName: "${data['teacherName']}"');
        print('[DEBUG]   subjectName: "${data['subjectName']}"');
        print('[DEBUG]   status: "${data['status']}"');
        print('[DEBUG]   createdAt: ${data['createdAt']}');
      }
      
      if (snapshot.docs.isEmpty) {
        print('[DEBUG] ⚠️ NO ABSENCES FOUND IN FIRESTORE');
      }
      print('[DEBUG] ===== END DEBUG =====');
    } catch (e) {
      print('[DEBUG] ERROR fetching absences: $e');
    }
  }

  Future<void> _syncStudentAbsenceCounters(
    String studentId,
    List<AbsenceFeatureModel> absences,
  ) async {
    final studentRef = _students.doc(studentId);
    final studentSnap = await studentRef.get();
    if (!studentSnap.exists) return;

    final data = studentSnap.data() ?? const <String, dynamic>{};
    final totalAbsence = absences.length;
    final justifiedAbsence = absences
        .where((a) => a.status == AbsenceStatus.justified)
        .length;
    final pendingAbsence = absences
        .where((a) => a.status == AbsenceStatus.pending)
        .length;

    final currentTotal = (data['totalAbsence'] as num?)?.toInt() ?? 0;
    final currentJustified = (data['justifiedAbsence'] as num?)?.toInt() ?? 0;
    final currentPending = (data['pendingAbsence'] as num?)?.toInt() ?? 0;

    if (currentTotal == totalAbsence &&
        currentJustified == justifiedAbsence &&
        currentPending == pendingAbsence) {
      return;
    }

    await studentRef.update({
      'totalAbsence': totalAbsence,
      'justifiedAbsence': justifiedAbsence,
      'pendingAbsence': pendingAbsence,
      'updatedAt': FieldValue.serverTimestamp(),
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
    String? authUid,
  }) async {
    final doc = _students.doc();
    await doc.set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'levelId': levelId.trim(),
      'groupId': groupId.trim(),
      'classId': classId.trim(),
      'authUid': authUid,  // ← Store Firebase Auth UID here!
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

  Future<String> submitAbsenceJustification({
    required String absenceId,
    required String studentId,
    required String reason,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
  }) async {
    final absenceRef = _absences.doc(absenceId);
    final studentRef = _students.doc(studentId);
    final justificationRef = _justifications.doc();

    final absenceSnap = await absenceRef.get();
    final studentSnap = await studentRef.get();

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
    final existingJustificationId =
        (absenceData['justificationId'] as String?)?.trim() ?? '';

    if (status != 'pending') {
      throw Exception('This absence has already been processed.');
    }

    if (existingJustificationId.isNotEmpty) {
      throw Exception('Justification already submitted for this absence.');
    }

    if (DateTime.now().isAfter(deadlineAt)) {
      throw Exception('Deadline expired. Justification is no longer allowed.');
    }

    final studentName =
        (studentData['fullName'] as String?)?.trim() ?? 'Unknown Student';
    final email = (studentData['email'] as String?)?.trim() ?? '';
    final levelId = (studentData['levelId'] as String?)?.trim() ?? '';
    final groupId = (studentData['groupId'] as String?)?.trim() ?? '';
    final levelName = await _resolveName(_levels, levelId, fallback: levelId);
    final groupName = await _resolveName(_groups, groupId, fallback: groupId);
    final teacherName =
        (absenceData['teacherName'] as String?)?.trim() ?? 'Unknown Teacher';
    final teacherId = (absenceData['teacherId'] as String?)?.trim() ?? '';
    final subjectId = (absenceData['subjectId'] as String?)?.trim() ?? '';
    final subjectName =
        (absenceData['subjectName'] as String?)?.trim() ??
        (absenceData['courseName'] as String?)?.trim() ??
        'Unknown Subject';

    DateTime absenceDate;
    final rawCreatedAt = absenceData['createdAt'];
    if (rawCreatedAt is Timestamp) {
      absenceDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      absenceDate = rawCreatedAt;
    } else {
      absenceDate = DateTime.now();
    }

    final storagePath =
        'justifications/$studentId/$absenceId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storageRef = FirebaseStorage.instance.ref(storagePath);
    final metadata = SettableMetadata(
      contentType: _resolveContentType(fileType, fileName),
    );

    String? uploadedFileUrl;
    try {
      final uploadTask = await storageRef.putData(fileBytes, metadata);
      uploadedFileUrl = await uploadTask.ref.getDownloadURL();

      await _firestore.runTransaction((tx) async {
        final refreshedAbsence = await tx.get(absenceRef);
        final refreshedStudent = await tx.get(studentRef);
        if (!refreshedAbsence.exists) {
          throw Exception('Absence no longer exists.');
        }
        if (!refreshedStudent.exists) {
          throw Exception('Student no longer exists.');
        }

        final refreshedData =
            refreshedAbsence.data() ?? const <String, dynamic>{};
        final refreshedStudentData =
            refreshedStudent.data() ?? const <String, dynamic>{};
        final refreshedStatus =
            (refreshedData['status'] as String?)?.toLowerCase() ?? 'pending';
        final refreshedJustificationId =
            (refreshedData['justificationId'] as String?)?.trim() ?? '';

        final pendingAbsence =
            (refreshedStudentData['pendingAbsence'] as num?)?.toInt() ?? 0;
        final justifiedAbsence =
            (refreshedStudentData['justifiedAbsence'] as num?)?.toInt() ?? 0;

        if (refreshedStatus != 'pending' ||
            refreshedJustificationId.isNotEmpty) {
          throw Exception('Justification already submitted for this absence.');
        }

        tx.set(justificationRef, {
          'absenceId': absenceId,
          'studentId': studentId,
          'studentName': studentName,
          'email': email,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'subjectId': subjectId,
          'subject': subjectName,
          'levelName': levelName,
          'groupName': groupName,
          'absenceDate': Timestamp.fromDate(absenceDate),
          'reason': reason.trim(),
          'fileUrl': uploadedFileUrl,
          'fileType': fileType.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(absenceRef, {
          'status': 'submitted',
          'justificationId': justificationRef.id,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(studentRef, {
          'pendingAbsence': pendingAbsence > 0 ? pendingAbsence - 1 : 0,
          'justifiedAbsence': justifiedAbsence + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return justificationRef.id;
    } catch (e) {
      if (uploadedFileUrl != null) {
        try {
          await storageRef.delete();
        } catch (_) {
          // Ignore cleanup failures.
        }
      }
      rethrow;
    }
  }

  Future<String> _resolveName(
    CollectionReference<Map<String, dynamic>> collection,
    String id, {
    required String fallback,
  }) async {
    if (id.trim().isEmpty) return fallback;
    final snap = await collection.doc(id).get();
    final data = snap.data();
    return (data?['name'] as String?)?.trim() ?? fallback;
  }

  String _resolveContentType(String fileType, String fileName) {
    final normalizedType = fileType.trim().toLowerCase();
    final normalizedName = fileName.trim().toLowerCase();

    if (normalizedType == 'pdf' || normalizedName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (['jpg', 'jpeg'].contains(normalizedType) ||
        normalizedName.endsWith('.jpg') ||
        normalizedName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (normalizedType == 'png' || normalizedName.endsWith('.png')) {
      return 'image/png';
    }
    return 'application/octet-stream';
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

    // Create expiration notification after transaction completes
    try {
      final absenceData = (await absenceRef.get()).data() ?? const <String, dynamic>{};
      final subjectName = (absenceData['subjectName'] as String?)?.trim() ?? 'An absence';
      
      await _notifications.doc().set({
        'studentId': studentId,
        'type': 'absenceexpired',
        'title': 'Absence Justification Expired',
        'message': 'You can no longer justify your absence in $subjectName',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'relatedAbsenceId': absenceId,
      });
    } catch (_) {
      // Silently skip notification creation errors
    }
  }

  double _calcAttendanceRate(int totalPresence, int totalAbsence) {
    final total = totalPresence + totalAbsence;
    if (total == 0) return 0;
    return totalPresence / total;
  }

  /// Create a notification for a student
  Future<String> createNotification({
    required String studentId,
    required String type,
    required String title,
    required String message,
    String? relatedAbsenceId,
    String? relatedJustificationId,
  }) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      throw Exception('Student ID is required');
    }

    final doc = _notifications.doc();
    await doc.set({
      'studentId': normalizedStudentId,
      'type': type.toLowerCase(),
      'title': title.trim(),
      'message': message.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      if (relatedAbsenceId != null && relatedAbsenceId.trim().isNotEmpty)
        'relatedAbsenceId': relatedAbsenceId.trim(),
      if (relatedJustificationId != null &&
          relatedJustificationId.trim().isNotEmpty)
        'relatedJustificationId': relatedJustificationId.trim(),
    });
    return doc.id;
  }

  /// Watch notifications for a student in real-time
  Stream<List<NotificationFeatureModel>> watchNotificationsByStudent(
    String studentId,
  ) {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return Stream.value(const <NotificationFeatureModel>[]);
    }

    return _notifications
        .where('studentId', isEqualTo: normalizedStudentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) =>
                  NotificationFeatureModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read for a student
  Future<void> markAllNotificationsAsRead(String studentId) async {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) return;

    final snapshot = await _notifications
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get count of unread notifications for a student
  Stream<int> watchUnreadNotificationCount(String studentId) {
    final normalizedStudentId = studentId.trim();
    if (normalizedStudentId.isEmpty) {
      return Stream.value(0);
    }

    return _notifications
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
