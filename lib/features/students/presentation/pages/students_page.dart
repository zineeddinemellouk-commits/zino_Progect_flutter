import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/features/students/presentation/pages/absence_tracker_page.dart';
import 'package:test/features/students/presentation/pages/student_attendance_page.dart';
import 'package:test/features/students/presentation/pages/student_profile_page.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF2F5FF),
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[850] : const Color(0xFFF2F5FF),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: Icon(
              Icons.logout_rounded,
              color: isDark ? Colors.white : Colors.black87,
            ),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═════ HEADER SECTION ═════
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF999999),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Greeting with name split across lines
                      Builder(
                        builder: (context) {
                          final fullName = students.isEmpty ? 'Student' : students.first.fullName;
                          final nameParts = fullName.trim().split(' ');
                          final firstName = nameParts.isNotEmpty ? nameParts.first : 'Student';
                          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF101828),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                  height: 1.2,
                                ),
                              ),
                              if (lastName.isNotEmpty)
                                Text(
                                  lastName,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF101828),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Inter',
                                    height: 1.0,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your attendance record is currently at $avgAttendanceText%. $avgAttendanceComment',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF666666),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ═════ ATTENDANCE SUMMARY CARD ═════
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF101828),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Summary',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF101828),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A40CF).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ACTIVE\nTERM',
                              style: const TextStyle(
                                color: Color(0xFF4A40CF),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Academic Year ${DateTime.now().year}-${DateTime.now().year + 1}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF999999),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Present Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL PRESENT',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF999999),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$presentCount',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF067647).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: Color(0xFF067647),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+2 this week',
                                  style: TextStyle(
                                    color: Color(0xFF067647),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Absent Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL ABSENT',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF999999),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$absentCount',
                            style: const TextStyle(
                              color: Color(0xFF101828),
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 12,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '1 Unexcused',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress Section with Light Background
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[700]?.withOpacity(0.3)
                              : const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Circular Progress
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 80,
                                    height: 80,
                                    child: CircularProgressIndicator(
                                      value: (avgAttendance / 100)
                                          .clamp(0.0, 1.0),
                                      strokeWidth: 7,
                                      backgroundColor: isDark
                                          ? Colors.grey[600]
                                          : const Color(0xFFD4DCFF),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        avgAttendance >= 80
                                            ? const Color(0xFF4A40CF)
                                            : avgAttendance >= 50
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${avgAttendance.toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Color(0xFF4A40CF),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Grade Label
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    avgAttendanceGrade,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF101828),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dean\'s List Eligible',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF999999),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                const SizedBox(height: 28),

                // ═════ PENDING ABSENCE ACTION CARD ═════
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A40CF), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A40CF).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        'Pending Absence Action',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        'You were marked absent for Advanced Calculus on Oct 24th. Please submit a justification within 48 hours.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Button
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
                            foregroundColor: const Color(0xFF4A40CF),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SUBMIT JUSTIFICATION',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const StudentAttendancePage(),
                  ),
                );
              },
            ),
            _NavItem(
              icon: Icons.assignment_rounded,
              label: 'REQUESTS',
              active: _selectedNavIndex == 2,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AbsenceTrackerPage()),
                );
              },
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'PROFILE',
              active: _selectedNavIndex == 3,
              onTap: () {
                final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StudentProfilePage(studentEmail: currentUserEmail),
                  ),
                );
              },
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
