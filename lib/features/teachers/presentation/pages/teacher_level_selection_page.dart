import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_subject_selection_page.dart';

/// Step 1: Level Selection Page
/// Shows all levels the teacher teaches in a grid/list format.
/// Each card displays level name, module count, and group count.
class TeacherLevelSelectionPage extends StatelessWidget {
  const TeacherLevelSelectionPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
  });

  final String teacherId;
  final String teacherEmail;

  @override
  Widget build(BuildContext context) {
    final service = TeachersFirestoreService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Select Section',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
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
                  'Could not load sections: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }

          final dashboard = snapshot.data;
          if (dashboard == null || dashboard.levels.isEmpty) {
            return Center(
              child: Text(
                'No sections assigned to you yet.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          final levels = dashboard.levels;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: levels.map((level) {
                final modulesForLevel = dashboard.subjects.length;
                final groupsForLevel = dashboard.groups
                    .where((g) => g.levelId == level.id)
                    .length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _LevelCard(
                    levelName: level.name,
                    moduleCount: modulesForLevel,
                    groupCount: groupsForLevel,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherSubjectSelectionPage(
                            teacherId: teacherId,
                            teacherEmail: teacherEmail,
                            selectedLevelId: level.id,
                            selectedLevelName: level.name,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.levelName,
    required this.moduleCount,
    required this.groupCount,
    required this.onTap,
  });

  final String levelName;
  final int moduleCount;
  final int groupCount;
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
              left: BorderSide(color: Theme.of(context).primaryColor, width: 5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.book_outlined,
                    label: '$moduleCount Modules',
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  _InfoChip(
                    icon: Icons.group_outlined,
                    label: '$groupCount Groups',
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
