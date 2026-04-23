import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_group_selection_page.dart';

/// Step 2: Subject/Module Selection Page
/// Shows all subjects the teacher teaches.
/// Displays breadcrumb: Section → Module → Group → Attendance
class TeacherSubjectSelectionPage extends StatelessWidget {
  const TeacherSubjectSelectionPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
    required this.selectedLevelId,
    required this.selectedLevelName,
  });

  final String teacherId;
  final String teacherEmail;
  final String selectedLevelId;
  final String selectedLevelName;

  @override
  Widget build(BuildContext context) {
    final service = TeachersFirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$selectedLevelName › Select Module',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Breadcrumb: Section › Module › Group › Attendance',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
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
                  'Could not load modules: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }

          final dashboard = snapshot.data;
          if (dashboard == null || dashboard.subjects.isEmpty) {
            return Center(
              child: Text(
                'No modules assigned to you yet.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          final subjects = dashboard.subjects;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: subjects.map((subject) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _SubjectCard(
                    subjectName: subject.name,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherGroupSelectionPage(
                            teacherId: teacherId,
                            teacherEmail: teacherEmail,
                            selectedLevelId: selectedLevelId,
                            selectedLevelName: selectedLevelName,
                            selectedSubjectId: subject.id,
                            selectedSubjectName: subject.name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subjectName, required this.onTap});

  final String subjectName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: const Color(0xFF7C3AED), // Purple/Indigo
                width: 5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF7C3AED),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Module',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
