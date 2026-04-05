import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/features/teachers/presentation/pages/teacher_attendance_groups_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key, this.teacherId, this.teacherEmail});

  static const routeName = '/features/teachers/profile';

  final String? teacherId;
  final String? teacherEmail;

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  final TeachersFirestoreService _service = TeachersFirestoreService();
  int _selectedNavIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      body: SafeArea(
        child: StreamBuilder<TeacherDashboardData?>(
          stream: _service.watchTeacherDashboard(
            teacherId: widget.teacherId,
            teacherEmail: widget.teacherEmail,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load teacher profile. ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF475467)),
                  ),
                ),
              );
            }

            final dashboard = snapshot.data;
            if (dashboard == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No teacher profile found for this account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF475467)),
                  ),
                ),
              );
            }

            final teacherName = _displayTeacherName(dashboard.teacher.fullName);
            final attendancePercent = (dashboard.attendanceRate * 100)
                .clamp(0, 100)
                .toStringAsFixed(1);

            return Column(
              children: [
                _TopHeader(
                  title: 'Academic Atelier',
                  onNotificationTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications.')),
                    );
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACADEMIC OVERVIEW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome, $teacherName',
                          style: const TextStyle(
                            fontSize: 50,
                            height: 0.95,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SearchField(
                          onChanged: (value) {
                            setState(
                              () => _searchQuery = value.trim().toLowerCase(),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _MarkAttendanceCard(
                          onStartSession: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TeacherAttendanceGroupsPage(
                                  teacherId: dashboard.teacher.id,
                                  teacherEmail: dashboard.teacher.email,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _AttendanceRateCard(
                          attendancePercent: attendancePercent,
                          bars: dashboard.attendanceBars,
                        ),
                        const SizedBox(height: 14),
                        _MetricCard(
                          label: 'TOTAL STUDENTS',
                          value: '${dashboard.students.length}',
                          valueColor: const Color(0xFF101828),
                        ),
                        const SizedBox(height: 12),
                        _MetricCard(
                          label: 'ATTENDANCE HISTORY',
                          value: dashboard.historyCount.toString().padLeft(
                            2,
                            '0',
                          ),
                          valueColor: const Color(0xFF4A40CF),
                        ),
                        const SizedBox(height: 14),
                        _SmallStatsRow(
                          subjects: dashboard.subjects.length,
                          classes: dashboard.classes.length,
                          activeStudents: dashboard.activeStudents,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'History by Group',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<TeacherAttendanceHistoryItem>>(
                          stream: _service.watchTeacherAttendanceHistory(
                            dashboard.teacher.id,
                          ),
                          builder: (context, historySnapshot) {
                            if (historySnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final allHistory =
                                historySnapshot.data ??
                                const <TeacherAttendanceHistoryItem>[];

                            final visibleHistory = allHistory.where((item) {
                              if (_searchQuery.isEmpty) {
                                return true;
                              }
                              return item.groupName.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  item.levelName.toLowerCase().contains(
                                    _searchQuery,
                                  );
                            }).toList();

                            if (visibleHistory.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE4E7EC),
                                  ),
                                ),
                                child: const Text(
                                  'No attendance history yet.',
                                  style: TextStyle(color: Color(0xFF667085)),
                                ),
                              );
                            }

                            return Column(
                              children: visibleHistory.take(6).map((item) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE4E7EC),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.levelName} • ${item.groupName}',
                                              style: const TextStyle(
                                                color: Color(0xFF101828),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatDate(item.createdAt),
                                            style: const TextStyle(
                                              color: Color(0xFF667085),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _statusChip(
                                            label:
                                                'Present ${item.presentCount}',
                                            color: const Color(0xFF067647),
                                            bg: const Color(0xFFE7F8EF),
                                          ),
                                          const SizedBox(width: 8),
                                          _statusChip(
                                            label: 'Absent ${item.absentCount}',
                                            color: const Color(0xFFB42318),
                                            bg: const Color(0xFFFEE4E2),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _TeacherBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() => _selectedNavIndex = index);
          if (index == 0) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_tabLabel(index))));
        },
      ),
    );
  }

  String _displayTeacherName(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty) return 'Teacher';
    return name;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _tabLabel(int index) {
    switch (index) {
      case 1:
        return 'Attendance section';
      case 2:
        return 'History section';
      case 3:
        return 'Profile section';
      default:
        return 'Dashboard section';
    }
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onNotificationTap});

  final String title;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F3FA),
        border: Border(bottom: BorderSide(color: Color(0xFFDCE1F2), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0F2E46),
            ),
            child: const Icon(Icons.person, color: Color(0xFF8ED8C5), size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A40CF),
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF475467),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDE5F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search students, groups or logs...',
          hintStyle: TextStyle(color: Color(0xFF667085), fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF667085)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _MarkAttendanceCard extends StatelessWidget {
  const _MarkAttendanceCard({required this.onStartSession});

  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3C2BDC), Color(0xFF4D3EE6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334A3ED6),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0x66FFFFFF),
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mark Attendance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Quickly log presence for your current active session.',
            style: TextStyle(color: Color(0xFFD8D8FF), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3C2BDC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onStartSession,
              child: const Text('Start Session Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRateCard extends StatelessWidget {
  const _AttendanceRateCard({
    required this.attendancePercent,
    required this.bars,
  });

  final String attendancePercent;
  final List<double> bars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ATTENDANCE RATE',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF027A48),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$attendancePercent%',
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                final value = (index < bars.length) ? bars[index] : 0.0;
                final height = (value.clamp(0, 100) / 100) * 62 + 10;
                final isPrimary = index == 3 || index == 4;

                return Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 24,
                      height: height,
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? const Color(0xFF4A40CF)
                            : const Color(0xFFE9EDF5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatsRow extends StatelessWidget {
  const _SmallStatsRow({
    required this.subjects,
    required this.classes,
    required this.activeStudents,
  });

  final int subjects;
  final int classes;
  final int activeStudents;

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Subjects', '$subjects'),
        const SizedBox(width: 8),
        tile('Classes', '$classes'),
        const SizedBox(width: 8),
        tile('Active', '$activeStudents'),
      ],
    );
  }
}

class _TeacherBottomNav extends StatelessWidget {
  const _TeacherBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const labels = ['DASHBOARD', 'ATTENDANCE', 'HISTORY', 'PROFILE'];
    const icons = [
      Icons.dashboard_rounded,
      Icons.fact_check_outlined,
      Icons.history_rounded,
      Icons.person_outline_rounded,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (index) {
          final selected = currentIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFE7ECFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 20,
                      color: selected
                          ? const Color(0xFF5B4EF3)
                          : const Color(0xFF667085),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFF5B4EF3)
                            : const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
