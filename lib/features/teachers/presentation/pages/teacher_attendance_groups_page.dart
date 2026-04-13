import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_group_attendance_page.dart';

class TeacherAttendanceGroupsPage extends StatelessWidget {
  const TeacherAttendanceGroupsPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
  });

  static const routeName = '/features/teachers/attendance/groups';

  final String teacherId;
  final String teacherEmail;

  @override
  Widget build(BuildContext context) {
    final service = TeachersFirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        title: const Text(
          'My Groups',
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'View All',
              style: TextStyle(
                color: Color(0xFF4A40CF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TeacherGroupOverview>>(
        stream: service.watchTeacherGroupsForSession(
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
                ),
              ),
            );
          }

          final groups = snapshot.data ?? const <TeacherGroupOverview>[];
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'No groups are assigned to this teacher yet.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            );
          }

          final groupsByLevel = <String, List<TeacherGroupOverview>>{};
          for (final group in groups) {
            final levelKey = group.levelName.trim().isEmpty
                ? 'Unknown Level'
                : group.levelName.trim();
            groupsByLevel.putIfAbsent(levelKey, () => <TeacherGroupOverview>[]);
            groupsByLevel[levelKey]!.add(group);
          }

          final orderedLevels = groupsByLevel.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            children: orderedLevels.map((levelName) {
              final levelGroups = groupsByLevel[levelName]!
                ..sort(
                  (a, b) => a.groupName.toLowerCase().compareTo(
                    b.groupName.toLowerCase(),
                  ),
                );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                    child: Text(
                      levelName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  ...levelGroups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _GroupCard(
                        group: group,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TeacherGroupAttendancePage(
                                teacherId: teacherId,
                                teacherEmail: teacherEmail,
                                group: group,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final TeacherGroupOverview group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4A40CF),
      const Color(0xFF0F766E),
      const Color(0xFF64748B),
    ];
    final stripeColor = colors[group.groupName.hashCode.abs() % colors.length];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: stripeColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LEVEL ${group.levelName.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFF4A40CF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.more_vert,
                    size: 18,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.groupName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${group.levelName} • Tap to mark attendance',
                style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE7ECFF),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 14,
                      color: Color(0xFF4A40CF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+${group.studentCount} Active Students',
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
