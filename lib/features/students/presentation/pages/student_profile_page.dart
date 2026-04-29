import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/services/firestore_service.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/main.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, this.studentId, this.studentEmail});

  final String? studentId;
  final String? studentEmail;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final StudentsFirestoreService _service = StudentsFirestoreService();
  final FirestoreService _firestoreService = FirestoreService();
  final DepartmentAuthService _authService = DepartmentAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isChangingPassword = false;

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HodooriLoginScreen()),
      (route) => false,
    );
  }

  Future<String> _getTeacherName(String teacherId) async {
    try {
      if (teacherId.trim().isEmpty) return 'Unassigned';
      final doc = await _firestoreService.watchTeachers()
          .firstWhere(
            (teachers) => teachers.any((t) => t.id == teacherId),
            orElse: () => [],
          );
      if (doc.isNotEmpty) {
        return doc.first.fullName.isNotEmpty ? doc.first.fullName : 'Unknown Teacher';
      }
      return 'Unknown Teacher';
    } catch (e) {
      print('[StudentProfile] Error fetching teacher name: $e');
      return 'Unknown Teacher';
    }
  }

  Future<String> _getGroupName(String groupId) async {
    try {
      if (groupId.trim().isEmpty) return 'Unknown Group';
      final doc = await _firestoreService.watchGroupsByLevel('')
          .firstWhere(
            (groups) => groups.any((g) => g.id == groupId),
            orElse: () => [],
          );
      if (doc.isNotEmpty) {
        return doc.first.name.isNotEmpty ? doc.first.name : groupId;
      }
      return groupId;
    } catch (e) {
      print('[StudentProfile] Error fetching group name: $e');
      return groupId;
    }
  }

  Future<String> _getLevelName(String levelId) async {
    try {
      if (levelId.trim().isEmpty) return 'Unknown';
      final doc = await _firestoreService.watchLevels()
          .firstWhere(
            (levels) => levels.any((l) => l.id == levelId),
            orElse: () => [],
          );
      if (doc.isNotEmpty) {
        return doc.first.name.isNotEmpty ? doc.first.name : levelId;
      }
      return levelId;
    } catch (e) {
      print('[StudentProfile] Error fetching level name: $e');
      return levelId;
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== HEADER =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A40CF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Secure your account',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ===== CONTENT =====
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Password
                        Text(
                          'Current Password',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: currentPasswordController,
                          obscureText: !showCurrentPassword,
                          decoration: InputDecoration(
                            hintText: 'Enter your current password',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF4A40CF), width: 2),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setDialogState(() {
                                showCurrentPassword = !showCurrentPassword;
                              }),
                              child: Icon(
                                showCurrentPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF4A40CF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // New Password
                        Text(
                          'New Password',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: newPasswordController,
                          obscureText: !showNewPassword,
                          decoration: InputDecoration(
                            hintText: 'At least 6 characters',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF4A40CF), width: 2),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setDialogState(() {
                                showNewPassword = !showNewPassword;
                              }),
                              child: Icon(
                                showNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF4A40CF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        Text(
                          'Confirm Password',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: !showConfirmPassword,
                          decoration: InputDecoration(
                            hintText: 'Confirm your new password',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE0E7FF)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF4A40CF), width: 2),
                            ),
                            suffixIcon: GestureDetector(
                              onTap: () => setDialogState(() {
                                showConfirmPassword = !showConfirmPassword;
                              }),
                              child: Icon(
                                showConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF4A40CF),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== ACTION BUTTONS =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () {
                                  Navigator.pop(dialogContext);
                                  currentPasswordController.dispose();
                                  newPasswordController.dispose();
                                  confirmPasswordController.dispose();
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isChangingPassword
                              ? null
                              : () async {
                                  final currentPassword =
                                      currentPasswordController.text.trim();
                                  final newPassword =
                                      newPasswordController.text.trim();
                                  final confirmPassword =
                                      confirmPasswordController.text.trim();

                                  // Validation
                                  if (currentPassword.isEmpty) {
                                    _showErrorMessage(
                                        'Please enter current password');
                                    return;
                                  }

                                  if (newPassword.isEmpty) {
                                    _showErrorMessage(
                                        'Please enter new password');
                                    return;
                                  }

                                  if (newPassword != confirmPassword) {
                                    _showErrorMessage(
                                        'New passwords do not match');
                                    return;
                                  }

                                  if (newPassword.length < 6) {
                                    _showErrorMessage(
                                        'Password must be at least 6 characters');
                                    return;
                                  }

                                  setState(() => _isChangingPassword = true);

                                  try {
                                    final user = _auth.currentUser;
                                    if (user?.email == null) {
                                      throw Exception(
                                          'No authenticated user found');
                                    }

                                    print(
                                      '[StudentProfile] 🔐 Attempting password change for ${user!.email}',
                                    );

                                    // Step 1: Reauthenticate with current password
                                    print(
                                        '[StudentProfile] Step 1: Reauthenticating...');
                                    final credential =
                                        EmailAuthProvider.credential(
                                      email: user.email!,
                                      password: currentPassword,
                                    );

                                    await user.reauthenticateWithCredential(
                                        credential);
                                    print(
                                        '[StudentProfile] ✅ Reauthentication successful');

                                    // Step 2: Update password
                                    print(
                                        '[StudentProfile] Step 2: Updating password...');
                                    await user.updatePassword(newPassword);
                                    print(
                                        '[StudentProfile] ✅ Password updated successfully');

                                    // Step 3: Close dialog and show success
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }

                                    setState(() => _isChangingPassword = false);

                                    // Step 4: Show success message
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              '✅ Password changed successfully'),
                                          backgroundColor:
                                              Color(0xFF27AE60),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    setState(() => _isChangingPassword = false);

                                    print(
                                      '[StudentProfile] ❌ Firebase Auth Error: ${e.code} - ${e.message}',
                                    );

                                    String errorMessage =
                                        'Failed to change password';
                                    if (e.code == 'wrong-password') {
                                      errorMessage =
                                          'Current password is incorrect';
                                    } else if (e.code == 'weak-password') {
                                      errorMessage =
                                          'New password is too weak';
                                    } else if (e.code ==
                                        'requires-recent-login') {
                                      errorMessage =
                                          'Please logout and login again before changing password';
                                    } else if (e.code == 'user-mismatch') {
                                      errorMessage =
                                          'User account mismatch. Please try again.';
                                    } else {
                                      errorMessage =
                                          e.message ?? errorMessage;
                                    }

                                    if (dialogContext.mounted) {
                                      _showErrorMessageInDialog(
                                          dialogContext, errorMessage);
                                    }
                                  } catch (e) {
                                    setState(() => _isChangingPassword = false);
                                    print('[StudentProfile] ❌ Error: $e');

                                    if (dialogContext.mounted) {
                                      _showErrorMessageInDialog(
                                        dialogContext,
                                        'An unexpected error occurred: $e',
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A40CF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isChangingPassword
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Password',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorMessageInDialog(BuildContext dialogContext, String message) {
    if (dialogContext.mounted) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('algorithm')) return Icons.code;
    if (name.contains('neural') || name.contains('network')) return Icons.psychology;
    if (name.contains('ui') || name.contains('ux') || name.contains('design')) return Icons.palette;
    if (name.contains('software')) return Icons.computer;
    return Icons.book;
  }

  Color _getSubjectIconBgColor(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('algorithm')) return const Color(0xFF5B4EF3);
    if (name.contains('neural') || name.contains('network')) return const Color(0xFF067647);
    if (name.contains('ui') || name.contains('ux') || name.contains('design')) return const Color(0xFFF79009);
    if (name.contains('software')) return const Color(0xFF174A5A);
    return const Color(0xFF4A40CF);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF2F4FA),
      body: SafeArea(
        child: StreamBuilder<StudentFeatureModel?>(
          stream: ((widget.studentId ?? '').trim().isNotEmpty
                  ? _service.watchStudentById(widget.studentId!)
                  : _service.watchStudentByEmail(widget.studentEmail ?? ''))
              .map((students) => students.isNotEmpty ? students.first : null),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            final student = snapshot.data;
            if (student == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No profile data available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            }

            final initials = _getInitials(student.fullName);
            final studentIdDisplay = student.id.length > 4
                ? student.id.substring(student.id.length - 4).toUpperCase()
                : student.id.toUpperCase();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ===== BACK BUTTON =====
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[800]
                              : const Color(0xFFE7EBF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: isDark ? Colors.white : const Color(0xFF4A40CF),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== PROFILE HEADER CARD =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7EBF5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: const Color(0xFF174A5A),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Student ID Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8D2FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'STUDENT ID: 2024-$studentIdDisplay',
                            style: const TextStyle(
                              color: Color(0xFF4A40CF),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Student Name
                        Text(
                          student.fullName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF0F1F3D),
                            fontSize: 40,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Row
                        _profileInfoRow(
                          icon: Icons.mail_outline,
                          text: student.email,
                        ),
                        const SizedBox(height: 8),

                        // Level & Group Row - Dynamic Names
                        FutureBuilder<String>(
                          future: _getLevelName(student.levelId),
                          builder: (context, levelSnapshot) {
                            final levelName = levelSnapshot.data ?? 'Level ${student.levelId}';
                            
                            return FutureBuilder<String>(
                              future: _getGroupName(student.groupId),
                              builder: (context, groupSnapshot) {
                                final groupName = groupSnapshot.data ?? student.groupId;
                                
                                return _profileInfoRow(
                                  icon: Icons.school_outlined,
                                  text: '$levelName • $groupName',
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ===== SUBJECTS SECTION =====
                  StreamBuilder<List<SubjectModel>>(
                    stream: _firestoreService.watchSubjects(),
                    builder: (context, subjectsSnapshot) {
                      if (subjectsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      final subjects = subjectsSnapshot.data ?? [];
                      if (subjects.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Enrolled Subjects',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subjects.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final subject = subjects[index];
                              final iconBgColor =
                                  _getSubjectIconBgColor(subject.name);
                              final icon = _getSubjectIcon(subject.name);

                              return FutureBuilder<String>(
                                future: _getTeacherName(subject.teacherId),
                                builder: (context, teacherSnapshot) {
                                  final teacherName = teacherSnapshot.data ?? 'Loading...';

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : const Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.grey[700]!
                                            : const Color(0xFFE0E7FF),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon Container
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: iconBgColor,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              icon,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Subject Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subject.name,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F1F3D),
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Teacher: $teacherName',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : const Color(0xFF25324B),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Right Arrow
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark
                                              ? Colors.grey[500]
                                              : const Color(0xFF5B4EF3),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // ===== DIVIDER =====
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: isDark
                        ? Colors.grey[700]
                        : const Color(0xFFE0E7FF),
                  ),
                  const SizedBox(height: 24),

                  // ===== ACTION BUTTONS =====
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A40CF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _changePassword,
                      icon: const Icon(Icons.lock),
                      label: const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF5B4EF3)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF25324B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
