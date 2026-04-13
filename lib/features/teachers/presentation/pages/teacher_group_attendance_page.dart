import 'package:flutter/material.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';

class TeacherGroupAttendancePage extends StatefulWidget {
  const TeacherGroupAttendancePage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
    required this.group,
  });

  final String teacherId;
  final String teacherEmail;
  final TeacherGroupOverview group;

  @override
  State<TeacherGroupAttendancePage> createState() =>
      _TeacherGroupAttendancePageState();
}

class _TeacherGroupAttendancePageState extends State<TeacherGroupAttendancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeachersFirestoreService _service = TeachersFirestoreService();
  final Map<String, bool> _isPresentByStudentId = <String, bool>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.groupName,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              widget.group.levelName,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A40CF),
          unselectedLabelColor: const Color(0xFF667085),
          indicatorColor: const Color(0xFF4A40CF),
          tabs: const [
            Tab(text: 'Attendance'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAttendanceTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return StreamBuilder<List<StudentFeatureModel>>(
      stream: _service.watchTeacherGroupStudents(
        teacherId: widget.teacherId,
        teacherEmail: widget.teacherEmail,
        groupId: widget.group.groupId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load students: ${snapshot.error}'),
            ),
          );
        }

        final students = snapshot.data ?? const <StudentFeatureModel>[];
        for (final student in students) {
          _isPresentByStudentId.putIfAbsent(student.id, () => true);
        }

        if (students.isEmpty) {
          return const Center(
            child: Text(
              'No students in this group.',
              style: TextStyle(color: Color(0xFF667085)),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                itemCount: students.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = students[index];
                  final isPresent = _isPresentByStudentId[student.id] ?? true;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE8ECFF),
                          child: Text(
                            student.fullName.isEmpty
                                ? '?'
                                : student.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF4A40CF),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: const TextStyle(
                                  color: Color(0xFF101828),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                student.email,
                                style: const TextStyle(
                                  color: Color(0xFF667085),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selected: isPresent,
                          showCheckmark: false,
                          selectedColor: const Color(0xFFE7F8EF),
                          backgroundColor: const Color(0xFFF2F4F7),
                          side: BorderSide.none,
                          label: Text(
                            'Present',
                            style: TextStyle(
                              color: isPresent
                                  ? const Color(0xFF067647)
                                  : const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _isPresentByStudentId[student.id] = true;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          selected: !isPresent,
                          showCheckmark: false,
                          selectedColor: const Color(0xFFFEE4E2),
                          backgroundColor: const Color(0xFFF2F4F7),
                          side: BorderSide.none,
                          label: Text(
                            'Absent',
                            style: TextStyle(
                              color: !isPresent
                                  ? const Color(0xFFB42318)
                                  : const Color(0xFF667085),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() {
                              _isPresentByStudentId[student.id] = false;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitAttendance(students),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A40CF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Attendance'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<List<TeacherAttendanceHistoryItem>>(
      stream: _service.watchGroupAttendanceHistory(
        widget.teacherId,
        widget.group.groupId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Could not load history: ${snapshot.error}'),
            ),
          );
        }

        final history = snapshot.data ?? const <TeacherAttendanceHistoryItem>[];

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No attendance history yet.',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          itemCount: history.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final record = history[index];
            final dateStr = _formatDate(record.createdAt);

            return _buildHistoryCard(record, dateStr);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(
    TeacherAttendanceHistoryItem record,
    String dateStr,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(record.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0EA5E9)),
                ),
                child: Text(
                  '${record.totalStudents} students',
                  style: const TextStyle(
                    color: Color(0xFF0369A1),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStat(
                  label: 'Present',
                  count: record.presentCount,
                  color: const Color(0xFF067647),
                  bgColor: const Color(0xFFE7F8EF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAttendanceStat(
                  label: 'Absent',
                  count: record.absentCount,
                  color: const Color(0xFFB42318),
                  bgColor: const Color(0xFFFEE4E2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showAttendanceDetails(record),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF4A40CF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF4A40CF),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  void _showAttendanceDetails(TeacherAttendanceHistoryItem record) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Attendance Details - ${_formatDate(record.createdAt)}',
          style: const TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailsSection(
                  title: 'Present (${record.presentCount})',
                  color: const Color(0xFF067647),
                  count: record.presentCount,
                ),
                const SizedBox(height: 16),
                _buildDetailsSection(
                  title: 'Absent (${record.absentCount})',
                  color: const Color(0xFFB42318),
                  count: record.absentCount,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required Color color,
    required int count,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count student${count != 1 ? 's' : ''}',
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAttendance(List<StudentFeatureModel> students) async {
    setState(() => _isSubmitting = true);
    try {
      final payload = <String, bool>{
        for (final student in students)
          student.id: _isPresentByStudentId[student.id] ?? true,
      };

      await _service.submitGroupAttendance(
        teacherId: widget.teacherId,
        group: widget.group,
        isPresentByStudentId: payload,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance submitted and saved to history.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
