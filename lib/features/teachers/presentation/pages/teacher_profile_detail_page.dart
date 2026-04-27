import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/main.dart';

class TeacherProfileDetailPage extends StatefulWidget {
  const TeacherProfileDetailPage({
    super.key,
    this.teacherId,
    this.teacherEmail,
  });

  final String? teacherId;
  final String? teacherEmail;

  @override
  State<TeacherProfileDetailPage> createState() =>
      _TeacherProfileDetailPageState();
}

class _TeacherProfileDetailPageState extends State<TeacherProfileDetailPage> {
  final TeachersFirestoreService _service = TeachersFirestoreService();
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

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Change Password',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Enter your current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDDD)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'At least 6 characters',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDDD)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Confirm your new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFDDD)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _isChangingPassword
                ? null
                : () async {
                    final currentPassword = currentPasswordController.text
                        .trim();
                    final newPassword = newPasswordController.text.trim();
                    final confirmPassword = confirmPasswordController.text
                        .trim();

                    // Validation
                    if (currentPassword.isEmpty) {
                      _showErrorMessage('Please enter current password');
                      return;
                    }

                    if (newPassword.isEmpty) {
                      _showErrorMessage('Please enter new password');
                      return;
                    }

                    if (newPassword != confirmPassword) {
                      _showErrorMessage('New passwords do not match');
                      return;
                    }

                    if (newPassword.length < 6) {
                      _showErrorMessage(
                        'Password must be at least 6 characters',
                      );
                      return;
                    }

                    setState(() => _isChangingPassword = true);

                    try {
                      final user = _auth.currentUser;
                      if (user?.email == null) {
                        throw Exception('No authenticated user found');
                      }

                      print(
                        '[TeacherProfile] 🔐 Attempting password change for ${user!.email}',
                      );

                      // Step 1: Reauthenticate with current password
                      print('[TeacherProfile] Step 1: Reauthenticating...');
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(credential);
                      print('[TeacherProfile] ✅ Reauthentication successful');

                      // Step 2: Update password
                      print('[TeacherProfile] Step 2: Updating password...');
                      await user.updatePassword(newPassword);
                      print('[TeacherProfile] ✅ Password updated successfully');

                      // Step 3: Close dialog and show success
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      setState(() => _isChangingPassword = false);

                      // Step 4: Show success message using post-frame callback
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Password changed successfully'),
                              backgroundColor: Color(0xFF27AE60),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      });

                      currentPasswordController.dispose();
                      newPasswordController.dispose();
                      confirmPasswordController.dispose();
                    } on FirebaseAuthException catch (e) {
                      setState(() => _isChangingPassword = false);

                      print(
                        '[TeacherProfile] ❌ Firebase Auth Error: ${e.code} - ${e.message}',
                      );

                      String errorMessage = 'Failed to change password';
                      if (e.code == 'wrong-password') {
                        errorMessage = 'Current password is incorrect';
                      } else if (e.code == 'weak-password') {
                        errorMessage = 'New password is too weak';
                      } else if (e.code == 'requires-recent-login') {
                        errorMessage =
                            'Please logout and login again before changing password';
                      } else if (e.code == 'user-mismatch') {
                        errorMessage =
                            'User account mismatch. Please try again.';
                      } else {
                        errorMessage = e.message ?? errorMessage;
                      }

                      if (dialogContext.mounted) {
                        _showErrorMessageInDialog(dialogContext, errorMessage);
                      }
                    } catch (e) {
                      setState(() => _isChangingPassword = false);
                      print('[TeacherProfile] ❌ Unexpected Error: $e');

                      if (dialogContext.mounted) {
                        _showErrorMessageInDialog(
                          dialogContext,
                          'An unexpected error occurred: $e',
                        );
                      }
                    }
                  },
            child: _isChangingPassword
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Update Password'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F4),
        elevation: 0,
        titleSpacing: 12,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF0F2E46),
              child: Icon(Icons.person, color: Color(0xFF8ED8C5), size: 20),
            ),
            SizedBox(width: 10),
            Text(
              'Profile',
              style: TextStyle(
                color: Color(0xFF101828),
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Icon(Icons.settings, color: Color(0xFF5B4EF3), size: 26),
          ),
        ],
      ),
      body: StreamBuilder<TeacherDashboardData?>(
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
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
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
                  'No profile data available',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            );
          }

          final teacher = dashboard.teacher;
          final initials = _getInitials(teacher.fullName);
          final groups = dashboard.groups;
          final subjects = dashboard.subjects;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EBF5),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
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
                          'SCHOLAR ID: ${_buildScholarId(teacher.id)}',
                          style: const TextStyle(
                            color: Color(0xFF4A40CF),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _formatDisplayName(teacher.fullName),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF0F1F3D),
                          fontSize: 66,
                          height: 0.98,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _profileInfoRow(
                        icon: Icons.mail_outline,
                        text: teacher.email,
                      ),
                      const SizedBox(height: 6),
                      _profileInfoRow(
                        icon: Icons.school_outlined,
                        text: _buildFacultyText(dashboard),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // Divider
                Container(height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 24),

                // Subjects Section
                if (subjects.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '📚 My Subjects',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1565C0)),
                        ),
                        child: Text(
                          subject.name,
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Groups Section
                if (groups.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '👥 My Groups',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: groups.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, index) {
                        final group = groups[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Level: ${group.levelId}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Divider
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 24),

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
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

                // Logout Button
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
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _buildScholarId(String teacherId) {
    final clean = teacherId.trim().toUpperCase();
    if (clean.isEmpty) return '2026-TEACHER';
    if (clean.length <= 10) return clean;
    return clean.substring(0, 10);
  }

  String _formatDisplayName(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty) return 'Teacher';
    return name.replaceAll(' ', '\n');
  }

  String _buildFacultyText(TeacherDashboardData dashboard) {
    if (dashboard.levels.isNotEmpty) {
      return 'Faculty • ${dashboard.levels.first.name}';
    }
    return 'Faculty of Sciences';
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
