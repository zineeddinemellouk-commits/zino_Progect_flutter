import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/models/absence_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';

/// Model for subject attendance statistics
class SubjectAttendanceModel {
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final int totalPresent;
  final int totalAbsent;
  final double attendancePercentage;

  SubjectAttendanceModel({
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.totalPresent,
    required this.totalAbsent,
  }) : attendancePercentage = _calculateAttendancePercentage(
    totalPresent,
    totalAbsent,
  );

  static double _calculateAttendancePercentage(
    int present,
    int absent,
  ) {
    final total = present + absent;
    if (total == 0) return 0;
    return ((present / total) * 100).clamp(0, 100);
  }

  int get totalSessions => totalPresent + totalAbsent;
  bool get isLowAttendance => attendancePercentage < 70;

  @override
  String toString() =>
      'SubjectAttendance($subjectName: $totalPresent present, $totalAbsent absent, $attendancePercentage%)';
}

/// Service to fetch and calculate attendance data from Firestore
class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches attendance statistics grouped by subject for a student
  /// Returns a stream of subject attendance data sorted by lowest attendance first
  Stream<List<SubjectAttendanceModel>> getStudentAttendanceBySubject(
    String studentId,
  ) {
    final normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      return Stream.value(const []);
    }

    // Watch absences for this student
    return _firestore
        .collection('absences')
        .where('studentId', isEqualTo: normalizedStudentId)
        .snapshots()
        .asyncMap((absenceSnapshot) async {
          if (absenceSnapshot.docs.isEmpty) {
            return const [];
          }

          // Parse all absences
          final absences = absenceSnapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.id, doc.data()))
              .toList();

          // Get unique subject IDs from absences
          final subjectIds = absences.map((a) => a.subjectId).toSet().toList();

          if (subjectIds.isEmpty) {
            return const [];
          }

          // Fetch subjects data
          final subjectsData = await Future.wait(
            subjectIds.map((id) =>
                _firestore.collection('subjects').doc(id).get()),
          );

          final subjects = <String, SubjectModel>{};
          for (final doc in subjectsData) {
            if (doc.exists) {
              final subject = SubjectModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
              subjects[doc.id] = subject;
            }
          }

          // Get unique teacher IDs
          final teacherIds = subjects.values
              .map((s) => s.teacherId)
              .toSet()
              .toList();

          // Fetch teachers data
          final teachersData = await Future.wait(
            teacherIds.map((id) =>
                _firestore.collection('teachers').doc(id).get()),
          );

          final teachers = <String, TeacherModel>{};
          for (final doc in teachersData) {
            if (doc.exists) {
              final teacher = TeacherModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
              teachers[doc.id] = teacher;
            }
          }

          // Group absences by subject and calculate statistics
          final absencesBySubject = <String, List<AbsenceModel>>{};
          for (final absence in absences) {
            if (!absencesBySubject.containsKey(absence.subjectId)) {
              absencesBySubject[absence.subjectId] = [];
            }
            absencesBySubject[absence.subjectId]!.add(absence);
          }

          // Build attendance statistics per subject
          final stats = <SubjectAttendanceModel>[];

          for (final subjectId in subjectIds) {
            final subject = subjects[subjectId];
            final teacher = subject != null ? teachers[subject.teacherId] : null;

            if (subject == null || teacher == null) continue;

            final subjectAbsences = absencesBySubject[subjectId] ?? [];

            // Fetch session count from 'attendance' collection for this subject
            // (sessions are recorded when teacher marks attendance)
            final sessionSnapshot = await _firestore
                .collection('attendance')
                .where('subjectId', isEqualTo: subjectId)
                .where('studentId', isEqualTo: normalizedStudentId)
                .get();

            final totalSessions = sessionSnapshot.docs.length;
            final totalAbsent = subjectAbsences.length;
            final totalPresent =
                totalSessions > 0 ? (totalSessions - totalAbsent).clamp(0, totalSessions) : 0;

            stats.add(
              SubjectAttendanceModel(
                subjectId: subjectId,
                subjectName: subject.name,
                teacherId: teacher.id,
                teacherName: teacher.fullName,
                totalPresent: totalPresent,
                totalAbsent: totalAbsent,
              ),
            );
          }

          // Sort by lowest attendance first
          stats.sort((a, b) =>
              a.attendancePercentage.compareTo(b.attendancePercentage));

          return stats;
        });
  }

  /// Alternative method: Get attendance data using a specific date range
  Stream<List<SubjectAttendanceModel>> getStudentAttendanceByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStudentId = studentId.trim();

    if (normalizedStudentId.isEmpty) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('absences')
        .where('studentId', isEqualTo: normalizedStudentId)
        .where('absenceDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('absenceDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .asyncMap((absenceSnapshot) async {
          // Same logic as getStudentAttendanceBySubject
          if (absenceSnapshot.docs.isEmpty) {
            return const [];
          }

          final absences = absenceSnapshot.docs
              .map((doc) => AbsenceModel.fromMap(doc.id, doc.data()))
              .toList();

          final subjectIds = absences.map((a) => a.subjectId).toSet().toList();

          if (subjectIds.isEmpty) {
            return const [];
          }

          final subjectsData = await Future.wait(
            subjectIds.map((id) =>
                _firestore.collection('subjects').doc(id).get()),
          );

          final subjects = <String, SubjectModel>{};
          for (final doc in subjectsData) {
            if (doc.exists) {
              final subject = SubjectModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
              subjects[doc.id] = subject;
            }
          }

          final teacherIds = subjects.values
              .map((s) => s.teacherId)
              .toSet()
              .toList();

          final teachersData = await Future.wait(
            teacherIds.map((id) =>
                _firestore.collection('teachers').doc(id).get()),
          );

          final teachers = <String, TeacherModel>{};
          for (final doc in teachersData) {
            if (doc.exists) {
              final teacher = TeacherModel.fromMap(
                doc.id,
                doc.data() as Map<String, dynamic>,
              );
              teachers[doc.id] = teacher;
            }
          }

          final absencesBySubject = <String, List<AbsenceModel>>{};
          for (final absence in absences) {
            if (!absencesBySubject.containsKey(absence.subjectId)) {
              absencesBySubject[absence.subjectId] = [];
            }
            absencesBySubject[absence.subjectId]!.add(absence);
          }

          final stats = <SubjectAttendanceModel>[];

          for (final subjectId in subjectIds) {
            final subject = subjects[subjectId];
            final teacher = subject != null ? teachers[subject.teacherId] : null;

            if (subject == null || teacher == null) continue;

            final subjectAbsences = absencesBySubject[subjectId] ?? [];

            final sessionSnapshot = await _firestore
                .collection('attendance')
                .where('subjectId', isEqualTo: subjectId)
                .where('studentId', isEqualTo: normalizedStudentId)
                .where('date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
                .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
                .get();

            final totalSessions = sessionSnapshot.docs.length;
            final totalAbsent = subjectAbsences.length;
            final totalPresent =
                totalSessions > 0 ? (totalSessions - totalAbsent).clamp(0, totalSessions) : 0;

            stats.add(
              SubjectAttendanceModel(
                subjectId: subjectId,
                subjectName: subject.name,
                teacherId: teacher.id,
                teacherName: teacher.fullName,
                totalPresent: totalPresent,
                totalAbsent: totalAbsent,
              ),
            );
          }

          stats.sort((a, b) =>
              a.attendancePercentage.compareTo(b.attendancePercentage));

          return stats;
        });
  }
}
