import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/student_feature_model.dart';
import 'package:test/services/department_auth_service.dart';
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
              backgroundColor: const Color(0xFF2563EB),
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
                        '[StudentProfile] 🔐 Attempting password change for ${user!.email}',
                      );

                      // Step 1: Reauthenticate with current password
                      print('[StudentProfile] Step 1: Reauthenticating...');
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassword,
                      );

                      await user.reauthenticateWithCredential(credential);
                      print('[StudentProfile] ✅ Reauthentication successful');

                      // Step 2: Update password
                      print('[StudentProfile] Step 2: Updating password...');
                      await user.updatePassword(newPassword);
                      print('[StudentProfile] ✅ Password updated successfully');

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
                    } on FirebaseAuthException catch (e) {
                      setState(() => _isChangingPassword = false);

                      print(
                        '[StudentProfile] ❌ Firebase Auth Error: ${e.code} - ${e.message}',
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
                      print('[StudentProfile] ❌ Unexpected Error: $e');

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<StudentFeatureModel?>(
        stream:
            ((widget.studentId ?? '').trim().isNotEmpty
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with initials
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Student ID Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'STUDENT ID: $studentIdDisplay',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Student Name
                  Text(
                    student.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        student.email,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Faculty/Group row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${student.groupId} - Level ${student.levelId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: isDark ? Colors.grey[700] : Colors.grey[200],
                  ),
                  const SizedBox(height: 32),

                  // Change Password Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _changePassword,
                      child: const Text(
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
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _logout,
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
}
