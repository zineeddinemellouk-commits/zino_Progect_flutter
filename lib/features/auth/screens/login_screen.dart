import 'dart:math';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test/services/department_auth_service.dart';

// ========================================
// Login Screen
// Handles user sign-in, credential checks,
// and entry into the role-based app flow.
// ========================================

class HodooriLoginScreen extends StatefulWidget {
  const HodooriLoginScreen({super.key});

  @override
  State<HodooriLoginScreen> createState() => _HodooriLoginScreenState();
}

class _HodooriLoginScreenState extends State<HodooriLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Student';
  bool _passwordVisible = false;
  bool _isSigningIn = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Firebase helpers (from original login_page.dart) ──────────────

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console.';
      case 'invalid-credential':
      case 'invalid-email':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  String _platformErrorMessage(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code.contains('operation_not_allowed') ||
        message.contains('operation is not allowed')) {
      return 'Email/password sign-in is disabled in Firebase Console.';
    }
    return e.message ?? 'Login failed due to a platform error.';
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final roleSnapshot = _selectedRole;
    final authService = DepartmentAuthService();

    setState(() => _isSigningIn = true);
    try {
      final profile = await authService.signInWithRole(
        email: email,
        password: password,
        expectedRole: roleSnapshot,
      );

      if (!mounted) return;

      // Navigate to destination (this will be handled by parent widget)
      // For now, just signal successful login
    } on FirebaseAuthException catch (e) {
      // Auto-create department account if not found
      if (roleSnapshot == 'Department' && e.code == 'user-not-found') {
        try {
          await authService.createDepartmentAccount(
            email: email,
            password: password,
          );
          final profile = await authService.signInWithRole(
            email: email,
            password: password,
            expectedRole: roleSnapshot,
          );
          if (!mounted) return;
          return;
        } on FirebaseAuthException catch (createError) {
          if (!mounted) return;
          _showError(_authErrorMessage(createError));
          return;
        }
      }

      // Repair missing department profile
      if (roleSnapshot == 'Department' && e.code == 'profile-not-found') {
        try {
          await authService.ensureDepartmentProfileForCredentials(
            email: email,
            password: password,
          );
          final profile = await authService.signInWithRole(
            email: email,
            password: password,
            expectedRole: roleSnapshot,
          );
          if (!mounted) return;
          return;
        } on FirebaseAuthException catch (repairError) {
          if (!mounted) return;
          _showError(_authErrorMessage(repairError));
          return;
        }
      }

      if (!mounted) return;
      _showError(_authErrorMessage(e));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'A Firebase error occurred.');
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showError(_platformErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      _showError('Login failed. Please verify your credentials.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();
    var isSending = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email))
                      return 'Enter a valid email';
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
                          if (resetFormKey.currentState?.validate() != true)
                            return;
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

  // ── Animations ────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;

    return Scaffold(
      body: Stack(
        children: [
          // Premium animated background
          _buildPremiumBackground(),
          
          // Main content with fade animation
          FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Premium Background with Animated Elements ──────────────────────

  Widget _buildPremiumBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF0F4F8),
            const Color(0xFFE8EEF7),
            const Color(0xFFEBF0F7),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated gradient orbs
          Positioned(
            top: -100,
            left: -50,
            child: _buildAnimatedOrb(
              size: 300,
              color: const Color(0xFF2563EB).withOpacity(0.08),
              duration: 8000,
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _buildAnimatedOrb(
              size: 280,
              color: const Color(0xFF1F3A93).withOpacity(0.06),
              duration: 10000,
            ),
          ),
          Positioned(
            top: 200,
            right: -40,
            child: _buildAnimatedOrb(
              size: 200,
              color: const Color(0xFF7C3AED).withOpacity(0.05),
              duration: 12000,
            ),
          ),

          // Subtle grid pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _PremiumGridPainter(),
            ),
          ),

          // Top accent light
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFFFFF).withOpacity(0.3),
                    const Color(0xFFFFFFFF).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated Orb Widget ────────────────────────────────────────────

  Widget _buildAnimatedOrb({
    required double size,
    required Color color,
    required int duration,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: duration),
      curve: Curves.linear,
      builder: (context, value, child) {
        final offset = sin(value * 2 * 3.14159) * 30;
        return Transform.translate(
          offset: Offset(offset, offset * 0.5),
          child: child,
        );
      },
      onEnd: () {
        // Loop animation
        setState(() {});
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      padding: const EdgeInsets.symmetric(horizontal: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: _buildLogoSection(),
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            flex: 1,
            child: Center(
              child: _buildLoginCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLogoSection(),
          const SizedBox(height: 48),
          _buildLoginCard(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.7 + value * 0.3,
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2563EB).withOpacity(0.1),
                  const Color(0xFF1F3A93).withOpacity(0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Image.asset(
              'assets/l10n/images/logo_hodori.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // App title animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1400),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: const Text(
            'HODORI',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3A93),
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Tagline animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1600),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 12 * (1 - value)),
                child: child,
              ),
            );
          },
          child: const Text(
            'Smart University Attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 9, 69, 174),
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Subtitle
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1800),
          builder: (context, value, child) {
            return Opacity(
              opacity: value * 0.7,
              child: child,
            );
          },
          child: const Text(
            'Secure • Fast • Reliable',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 9, 69, 174),
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromARGB(165, 255, 255, 255).withOpacity(0.95),
                    const Color.fromARGB(225, 255, 255, 255).withOpacity(0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1F3A93).withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 0,
                    offset: const Offset(0, 25),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.08),
                    blurRadius: 25,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(48),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F3A93),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to your account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Role selector
                    _buildRoleSelector(),
                    const SizedBox(height: 32),

                    // Email
                    _buildInputLabel('Email Address'),
                    const SizedBox(height: 10),
                    _buildEmailField(),
                    const SizedBox(height: 20),

                    // Password
                    _buildInputLabel('Password'),
                    const SizedBox(height: 10),
                    _buildPasswordField(),
                    const SizedBox(height: 20),

                    // Login button
                    _buildLoginButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = ['Student', 'Teacher', 'Department'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1F3A93)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
          letterSpacing: 0.2,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintText: 'your.email@university.edu',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFFD1D5DB),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.mail_outline_rounded,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Email is required';
          if (!value.contains('@')) return 'Enter a valid email';
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintText: '••••••••••••',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: Color(0xFFD1D5DB),
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _passwordVisible = !_passwordVisible),
              child: Icon(
                _passwordVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Password is required';
          if (value.length < 6) return 'Minimum 6 characters';
          return null;
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isSigningIn ? null : _handleLogin,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1F3A93)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFF1F3A93).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isSigningIn
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white.withOpacity(0.9)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Signing In...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                 
          ),
        ),
      ),
      
    );
  }
}

// ── Premium Grid Painter - Subtle animated background pattern ─────────────

class _PremiumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(0.04)
      ..strokeWidth = 1;

    // Draw subtle horizontal lines
    for (int i = 0; i < (size.height / 60).toInt(); i++) {
      canvas.drawLine(
        Offset(0, i * 60.0),
        Offset(size.width, i * 60.0),
        paint,
      );
    }

    // Draw subtle vertical lines
    for (int i = 0; i < (size.width / 60).toInt(); i++) {
      canvas.drawLine(
        Offset(i * 60.0, 0),
        Offset(i * 60.0, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PremiumGridPainter oldDelegate) => false;
}
