import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_attendance_groups_page.dart';
import 'package:test/models/subject_model.dart';

/// Step 2: Subject Selection Page
/// Can be reached directly from "Start Session Now" or from level selection.
class TeacherSubjectSelectionPage extends StatelessWidget {
  const TeacherSubjectSelectionPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
    this.selectedLevelId,
    this.selectedLevelName,
  });

  final String teacherId;
  final String teacherEmail;
  final String? selectedLevelId;
  final String? selectedLevelName;

  @override
  Widget build(BuildContext context) {
    final service = TeachersFirestoreService();
    final now = DateTime.now();
    final nextYearShort = ((now.year + 1) % 100).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A40CF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Subject Selection',
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: StreamBuilder<TeacherDashboardData?>(
        stream: service.watchTeacherDashboard(
          teacherId: teacherId,
          teacherEmail: teacherEmail,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load subjects: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF475467)),
                ),
              ),
            );
          }

          final dashboard = snapshot.data;
          if (dashboard == null) {
            return const SizedBox.shrink();
          }

          final groupsById = {
            for (final group in dashboard.groups) group.id.trim(): group,
          };
          final levelsById = {
            for (final level in dashboard.levels) level.id.trim(): level,
          };

          bool belongsToSelectedLevel(SubjectModel subject) {
            final wantedLevelId = (selectedLevelId ?? '').trim();
            if (wantedLevelId.isEmpty) return true;

            for (final classId in subject.classIds) {
              final group = groupsById[classId.trim()];
              if (group != null && group.levelId.trim() == wantedLevelId) {
                return true;
              }
            }
            return false;
          }

          final subjects = dashboard.subjects
              .where(belongsToSelectedLevel)
              .toList();

          if (subjects.isEmpty) {
            return const Center(
              child: Text(
                'No subjects assigned to you yet.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            );
          }

          String resolveLevelLabel(SubjectModel subject) {
            for (final classId in subject.classIds) {
              final group = groupsById[classId.trim()];
              if (group == null) continue;

              final level = levelsById[group.levelId.trim()];
              final levelName = (level?.name ?? '').trim();
              if (levelName.isNotEmpty) return levelName;
              if (group.levelId.trim().isNotEmpty) return group.levelId.trim();
            }

            final fallback = (selectedLevelName ?? '').trim();
            return fallback.isNotEmpty ? fallback : 'L1';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACADEMIC YEAR ${now.year}/$nextYearShort',
                  style: const TextStyle(
                    color: Color(0xFF4A40CF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subjects.length.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Active Subjects for Attendance',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1D2939),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                ...subjects.map((subject) {
                  final levelLabel = resolveLevelLabel(subject);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SubjectCard(
                      levelLabel: levelLabel,
                      subjectName: subject.name,
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(
                              milliseconds: 260,
                            ),
                            pageBuilder: (_, animation, __) => FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                              child: TeacherAttendanceGroupsPage(
                                teacherId: teacherId,
                                teacherEmail: teacherEmail,
                                selectedSubjectId: subject.id,
                                selectedSubjectName: subject.name,
                              ),
                            ),
                            transitionsBuilder:
                                (_, animation, __, child) => SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.06, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                  child: child,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.levelLabel,
    required this.subjectName,
    required this.onTap,
  });

  final String levelLabel;
  final String subjectName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF4A40CF), width: 4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL ${levelLabel.toUpperCase()}',
                        style: const TextStyle(
                          color: Color(0xFF4A40CF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFFB6B3CF),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF4A40CF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Select for Attendance'),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}