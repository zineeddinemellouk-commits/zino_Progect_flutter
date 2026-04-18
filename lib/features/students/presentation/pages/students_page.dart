import 'package:flutter/material.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/students/presentation/pages/absence_tracker_page.dart';
import 'package:test/main.dart'; // ✅ FIXED
import 'package:test/services/department_auth_service.dart';

extension AttendanceGrading on double {
  String get gradeLabel {
    if (this >= 0.8) return 'Excellent';
    if (this >= 0.5) return 'Average';
    return 'Needs Improvement';
  }

  Color get gradeColor {
    if (this >= 0.8) return const Color(0xFF4A40CF);
    if (this >= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }
}

class StudentsPage extends StatefulWidget {
  const StudentsPage({
    super.key,
    this.studentDocumentId,
    this.studentEmail,
    this.selfViewOnly = false,
  });

  static const routeName = '/features/students';

  final String? studentDocumentId;
  final String? studentEmail;
  final bool selfViewOnly;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final StudentsFirestoreService _service = StudentsFirestoreService();
  final DepartmentAuthService _authService = DepartmentAuthService();
  int _selectedNavIndex = 0;

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HodooriLoginScreen()), // ✅ FIXED
      (route) => false,
    );
  }

  Future<void> _showStudentFormDialog({StudentFeatureModel? existing}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _StudentFormDialog(existing: existing, service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5FF),
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF101828),
              child: Icon(Icons.school_rounded, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Text(
              'Academic Atelier',
              style: TextStyle(
                color: Color(0xFF2D3A8C),
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (!widget.selfViewOnly)
            IconButton(
              onPressed: () => _showStudentFormDialog(),
              icon: const Icon(
                Icons.person_add_alt_1,
                color: Color(0xFF2D3A8C),
              ),
            ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications are active.')),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: Color(0xFF2D3A8C),
            ),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF2D3A8C)),
          ),
        ],
      ),
      body: StreamBuilder<List<StudentFeatureModel>>(
        stream: widget.selfViewOnly
            ? ((widget.studentDocumentId ?? '').trim().isNotEmpty
                  ? _service.watchStudentById(widget.studentDocumentId!)
                  : _service.watchStudentByEmail(widget.studentEmail ?? ''))
            : _service.watchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load students: ${snapshot.error}'),
            );
          }

          final students = snapshot.data ?? const [];

          final firstStudent = students.isNotEmpty ? students.first : null;

          final avgAttendance = (firstStudent?.attendanceRate ?? 0) * 100;
          final avgAttendanceText = avgAttendance.toStringAsFixed(1);
          final avgAttendanceGrade =
              (firstStudent?.attendanceRate ?? 0).gradeLabel;
          final avgAttendanceComment = switch (avgAttendanceGrade) {
            'Excellent' => 'Great job — keep the momentum going.',
            'Average' => 'Solid progress — there is still room to improve.',
            _ => 'Let\'s work on raising the attendance average.',
          };
          final presentCount = firstStudent?.totalPresence ?? 0;
          final absentCount = firstStudent?.totalAbsence ?? 0;
          final activeTerm = DateTime.now().year;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  students.isEmpty
                      ? 'Hello, Student'
                      : 'Hello, ${students.first.fullName}',
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 44,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Average attendance is currently at ',
                      ),
                      TextSpan(
                        text: '$avgAttendanceText%. ',
                        style: const TextStyle(
                          color: Color(0xFF5145E5),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: 'You\'re doing great this semester!',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D101828),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Attendance\nSummary',
                              style: TextStyle(
                                color: Color(0xFF344054),
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7E9FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ACTIVE\nTERM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF515ECF),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Academic Year $activeTerm-${activeTerm + 1}',
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TOTAL PRESENT',
                        style: TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$presentCount',
                        style: const TextStyle(
                          color: Color(0xFF4A40CF),
                          fontSize: 58,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '^ +2 this week',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TOTAL ABSENT',
                        style: TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$absentCount',
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 56,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A 1 Unexcused',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 45,
                              height: 45,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 4,
                                    value: avgAttendance / 100,
                                    backgroundColor: const Color(0xFFD6DCFF),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4A40CF),
                                        ),
                                  ),
                                  Text(
                                    '$avgAttendanceText%',
                                    style: const TextStyle(
                                      color: Color(0xFF4A40CF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    avgAttendanceGrade,
                                    style: const TextStyle(
                                      color: Color(0xFF1D2939),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    avgAttendanceComment,
                                    style: const TextStyle(
                                      color: Color(0xFF98A2B3),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4636D9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Pending Absence Action',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        students.isEmpty
                            ? 'No students yet. Add a student to start tracking attendance.'
                            : 'Review absences and update attendance records from Firestore in real time.',
                        style: const TextStyle(
                          color: Color(0xFFD9D6FF),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AbsenceTrackerPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4636D9),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'SUBMIT JUSTIFICATION',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE5FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need help?',
                              style: TextStyle(
                                color: Color(0xFF4A40CF),
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Check the student handbook for attendance policies and guidelines.',
                              style: TextStyle(
                                color: Color(0xFF475467),
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.selfViewOnly)
                        InkWell(
                          onTap: () => _showStudentFormDialog(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.note_add_rounded,
                              color: Color(0xFF4A40CF),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFF),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'DASHBOARD',
              active: _selectedNavIndex == 0,
              onTap: () => setState(() => _selectedNavIndex = 0),
            ),
            _NavItem(
              icon: Icons.how_to_reg_rounded,
              label: 'ATTENDANCE',
              active: _selectedNavIndex == 1,
              onTap: () => setState(() => _selectedNavIndex = 1),
            ),
            _NavItem(
              icon: Icons.assignment_rounded,
              label: 'REQUESTS',
              active: _selectedNavIndex == 2,
              onTap: () {
                setState(() => _selectedNavIndex = 2);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Justification is disabled now.'),
                  ),
                );
              },
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'PROFILE',
              active: _selectedNavIndex == 3,
              onTap: () => setState(() => _selectedNavIndex = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({required this.existing, required this.service});

  final StudentFeatureModel? existing;
  final StudentsFirestoreService service;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String? _selectedLevelId;
  late String? _selectedGroupId;
  late String? _selectedClassId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(
      text: widget.existing?.fullName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existing?.email ?? '',
    );
    _selectedLevelId =
        widget.existing != null && widget.existing!.levelId.isNotEmpty
        ? widget.existing!.levelId
        : null;
    _selectedGroupId =
        widget.existing != null && widget.existing!.groupId.isNotEmpty
        ? widget.existing!.groupId
        : null;
    _selectedClassId =
        widget.existing != null && widget.existing!.classId.isNotEmpty
        ? widget.existing!.classId
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Student' : 'Edit Student'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, String>>>(
                  stream: widget.service.watchLevels(),
                  builder: (context, snapshot) {
                    final levels = snapshot.data ?? const [];
                    return DropdownButtonFormField<String>(
                      value: levels.any((l) => l['id'] == _selectedLevelId)
                          ? _selectedLevelId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Level',
                        border: OutlineInputBorder(),
                      ),
                      items: levels
                          .map(
                            (l) => DropdownMenuItem(
                              value: l['id'],
                              child: Text(l['name'] ?? l['id'] ?? '-'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedLevelId = value);
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select a level'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, String>>>(
                  stream: widget.service.watchGroups(),
                  builder: (context, snapshot) {
                    final groups = snapshot.data ?? const [];
                    return DropdownButtonFormField<String>(
                      value: groups.any((g) => g['id'] == _selectedGroupId)
                          ? _selectedGroupId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Group',
                        border: OutlineInputBorder(),
                      ),
                      items: groups
                          .map(
                            (g) => DropdownMenuItem(
                              value: g['id'],
                              child: Text(g['name'] ?? g['id'] ?? '-'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedGroupId = value);
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select a group'
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, String>>>(
                  stream: widget.service.watchClasses(),
                  builder: (context, snapshot) {
                    final classes = snapshot.data ?? const [];
                    return DropdownButtonFormField<String>(
                      value: classes.any((c) => c['id'] == _selectedClassId)
                          ? _selectedClassId
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items: classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c['id'],
                              child: Text(c['name'] ?? c['id'] ?? '-'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedClassId = value);
                      },
                      validator: (value) => value == null || value.isEmpty
                          ? 'Select a class'
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      if (widget.existing == null) {
        await widget.service.addStudent(
          fullName: _nameController.text,
          email: _emailController.text,
          levelId: _selectedLevelId!,
          groupId: _selectedGroupId!,
          classId: _selectedClassId!,
          attendancePercentage: 0,
        );
      } else {
        await widget.service.updateStudent(
          id: widget.existing!.id,
          fullName: _nameController.text,
          email: _emailController.text,
          levelId: _selectedLevelId!,
          groupId: _selectedGroupId!,
          classId: _selectedClassId!,
          attendancePercentage: 0,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'Student added successfully.'
                : 'Student updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF4A40CF) : const Color(0xFF667085),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF4A40CF)
                    : const Color(0xFF667085),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
