import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_group_attendance_page.dart';

/// Step 3: Group Selection Page
/// Shows all groups in the selected level.
/// Displays breadcrumb showing current position in the flow.
class TeacherGroupSelectionPage extends StatelessWidget {
  const TeacherGroupSelectionPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
    required this.selectedLevelId,
    required this.selectedLevelName,
    required this.selectedSubjectId,
    required this.selectedSubjectName,
  });

  final String teacherId;
  final String teacherEmail;
  final String selectedLevelId;
  final String selectedLevelName;
  final String selectedSubjectId;
  final String selectedSubjectName;

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
              '$selectedLevelName › $selectedSubjectName › Select Group',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            _BreadcrumbIndicator(
              steps: [
                ('Section', true),
                ('Module', true),
                ('Group', false),
                ('Attendance', false),
              ],
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
                  'Could not load groups: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }

          final dashboard = snapshot.data;
          if (dashboard == null) {
            return const SizedBox.shrink();
          }

          // Filter groups by selected level
          final groupsInLevel = dashboard.groups
              .where((group) => group.levelId == selectedLevelId)
              .toList();

          if (groupsInLevel.isEmpty) {
            return Center(
              child: Text(
                'No groups in this section.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: groupsInLevel.map((group) {
                // Count students in this group
                final studentCount = dashboard.students
                    .where((s) => s.groupId == group.id)
                    .length;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GroupCard(
                    groupName: group.name,
                    studentCount: studentCount,
                    onTap: () {
                      final groupOverview = TeacherGroupOverview(
                        groupId: group.id,
                        groupName: group.name,
                        levelId: group.levelId,
                        levelName: selectedLevelName,
                        studentCount: studentCount,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TeacherGroupAttendancePage(
                            teacherId: teacherId,
                            teacherEmail: teacherEmail,
                            group: groupOverview,
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.groupName,
    required this.studentCount,
    required this.onTap,
  });

  final String groupName;
  final int studentCount;
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
                color: Colors.green, // Green accent for groups
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
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$studentCount Students',
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

/// Breadcrumb indicator widget showing steps with completion status.
/// Blue for active/completed, grey for inactive.
class _BreadcrumbIndicator extends StatelessWidget {
  const _BreadcrumbIndicator({required this.steps});

  final List<(String label, bool isActive)> steps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: step.$2
                        ? Theme.of(context).primaryColor.withOpacity(0.15)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    step.$1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: step.$2
                          ? Theme.of(context).primaryColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
