// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/students/presentation/pages/students_page.dart';
import 'package:test/features/teachers/presentation/pages/teacher_profile_page.dart';
import 'package:test/models/app_user_profile.dart';
import 'package:test/pages/department_dashboard.dart' show DepartmentDashboard;
import 'package:test/pages/role_home_page.dart';
import 'package:test/services/department_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String selectedRole = "Student";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  bool _isSigningIn = false;

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console. '
            'Enable Authentication > Sign-in method > Email/Password.';
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  String _platformErrorMessage(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();

    if (code.contains('operation_not_allowed') ||
        code.contains('operation-not-allowed') ||
        message.contains('operation is not allowed')) {
      return 'Email/password sign-in is disabled in Firebase Console. '
          'Enable Authentication > Sign-in method > Email/Password.';
    }

    return e.message ?? 'Login failed due to a platform error.';
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
    
    // Clear password field for easier retry
    passwordController.clear();
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();
    var isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: resetFormKey,
                child: TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (resetFormKey.currentState?.validate() != true) {
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            await DepartmentAuthService()
                                .sendPasswordResetEmail(
                                  email: resetEmailController.text,
                                );
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password reset email sent. Check your inbox.',
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_authErrorMessage(e))),
                            );
                          } on PlatformException catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(_platformErrorMessage(e))),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to send reset email: $e'),
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSending = false);
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _changeRole(String role) {
    if (selectedRole == role) return;

    double targetPosition;
    if (role == "Student") {
      targetPosition = 0;
    } else if (role == "Teacher") {
      targetPosition = 1;
    } else {
      targetPosition = 2;
    }

    _slideAnimation =
        Tween<double>(
          begin: _slideAnimation.value,
          end: targetPosition,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _animationController.forward(from: 0);
    setState(() {
      selectedRole = role;
    });
  }

  Widget _destinationForProfile(AppUserProfile profile) {
    if (profile.role == 'Department') {
      return const DepartmentDashboard();
    }

    if (profile.role == 'Student') {
      return StudentsPage(
        selfViewOnly: true,
        studentDocumentId: profile.linkedDocumentId,
        studentEmail: profile.email,
      );
    }

    if (profile.role == 'Teacher') {
      return TeacherProfilePage(
        teacherId: profile.linkedDocumentId,
        teacherEmail: profile.email,
      );
    }

    return RoleHomePage(
      role: profile.role,
      email: profile.email,
      displayName: profile.displayName,
    );
  }

  Future<void> handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final selectedRoleSnapshot = selectedRole;
    final authService = DepartmentAuthService();

    setState(() => _isSigningIn = true);
    try {
      final profile = await authService.signInWithRole(
        email: email,
        password: password,
        expectedRole: selectedRoleSnapshot,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Login as ${profile.role} successful')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _destinationForProfile(profile),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        setState(() => _isSigningIn = false);
        return;
      }

      // Handle department account creation if needed
      if (selectedRoleSnapshot == 'Department' && e.code == 'user-not-found') {
        try {
          await authService.createDepartmentAccount(
            email: email,
            password: password,
          );

          final profile = await authService.signInWithRole(
            email: email,
            password: password,
            expectedRole: selectedRoleSnapshot,
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Department account created successfully.'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _destinationForProfile(profile),
            ),
          );
          return;
        } on FirebaseAuthException catch (createError) {
          if (!mounted) {
            setState(() => _isSigningIn = false);
            return;
          }
          await _showErrorDialog('❌ Account Creation Failed', _authErrorMessage(createError));
          return;
        }
      }

      if (selectedRoleSnapshot == 'Department' &&
          e.code == 'profile-not-found') {
        try {
          await authService.ensureDepartmentProfileForCredentials(
            email: email,
            password: password,
          );

          final profile = await authService.signInWithRole(
            email: email,
            password: password,
            expectedRole: selectedRoleSnapshot,
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Department profile repaired successfully.'),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _destinationForProfile(profile),
            ),
          );
          return;
        } on FirebaseAuthException catch (repairError) {
          if (!mounted) {
            setState(() => _isSigningIn = false);
            return;
          }
          await _showErrorDialog('❌ Profile Repair Failed', _authErrorMessage(repairError));
          return;
        }
      }

      // Show user-friendly error dialog for other auth failures
      await _showErrorDialog('❌ Login Failed', _authErrorMessage(e));
    } on FirebaseException catch (e) {
      if (!mounted) {
        setState(() => _isSigningIn = false);
        return;
      }
      final message = e.message ?? 'A Firebase error occurred. Please try again.';
      await _showErrorDialog('❌ Error', message);
    } on PlatformException catch (e) {
      if (!mounted) {
        setState(() => _isSigningIn = false);
        return;
      }
      await _showErrorDialog('❌ Platform Error', _platformErrorMessage(e));
    } catch (e) {
      if (!mounted) {
        setState(() => _isSigningIn = false);
        return;
      }
      debugPrint('[LoginPage] ❌ Unexpected error: $e');
      await _showErrorDialog(
        '❌ Unexpected Error',
        'Login failed. Please verify your email and password and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          /// Background
          Positioned(
            top: -100,
            left: -100,
            child: _blurCircle(const Color(0xFFB4C5FF), 300),
          ),
          Positioned(
            top: 200,
            right: -150,
            child: _blurCircle(const Color(0xFF6FFBBE), 400),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(width: 420, child: _loginCard()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // ignore: duplicate_ignore
        // ignore: deprecated_member_use
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: const SizedBox(),
      ),
    );
  }

  Widget _loginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 165, 162, 162).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),

                /// Logo
                Image.asset(
                  'assets/l10n/images/logo_hodori.png',
                  height: 100,
                  width: 100,
                ),

                const SizedBox(height: 30),

                /// ✅ Role Switcher with Animation
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E8EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Ensure minimum width to avoid negative constraints
                      double availableWidth = constraints.maxWidth > 0
                          ? constraints.maxWidth - 8
                          : 400 - 8;
                      double buttonWidth = availableWidth / 3;

                      return Stack(
                        children: [
                          AnimatedBuilder(
                            animation: _slideAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  _slideAnimation.value * buttonWidth,
                                  0,
                                ),
                                child: Container(
                                  width: buttonWidth,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            children: [
                              _roleButton("Student"),
                              _roleButton("Teacher"),
                              _roleButton("Department"),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                /// Email
                _inputField(
                  controller: emailController,
                  hint: "Email",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                /// Password
                _inputField(
                  controller: passwordController,
                  hint: "Password",
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Minimum 6 characters";
                    }
                    return null;
                  },
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSigningIn ? null : _showForgotPasswordDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ),

                const SizedBox(height: 25),

                /// ✅ BUTTON WORKING
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSigningIn ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004AC6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Role Button with Animation
  Widget _roleButton(String role) {
    bool isActive = selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _changeRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Center(
            child: Text(
              role,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF004AC6) : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEDEEF0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
