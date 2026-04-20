// ignore_for_file: deprecated_member_use
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:test/firebase_options.dart';
import 'pages/login_page.dart';
import 'package:test/pages/departement/ViewStudent.dart';
import 'package:test/pages/departement/groups_screen.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/students_screen.dart';
import 'package:test/features/teachers/presentation/pages/teacher_profile_page.dart';
import 'package:test/features/students/presentation/pages/students_page.dart';
import 'package:test/models/app_user_profile.dart';
import 'package:test/pages/department_dashboard.dart' show DepartmentDashboard;
import 'package:test/pages/role_home_page.dart';
import 'package:test/services/department_auth_service.dart';
import 'package:test/pages/department_settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/providers/locale_provider.dart';
import 'package:test/services/localization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ybpmzffutavfwcbfkjcq.supabase.co', // ← PASTE YOUR URL HERE
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlicG16ZmZ1dGF2ZndjYmZramNxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1MTYyMTMsImV4cCI6MjA5MjA5MjIxM30.7wB2kJww59dpgU751hzIyGE4R0SPPwatcH6Hx34fflU', // ← PASTE YOUR ANON KEY HERE
  );

  // Initialize localization service
  await LocalizationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentManagementProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hodoori - Smart Attendance',
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            brightness: Brightness.light,
          ),
          locale: localeProvider.currentLocale,
          supportedLocales: LocaleProvider.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) {
              return supportedLocales.first;
            }
            for (var supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return supportedLocales.first;
          },
          builder: (context, child) {
            return Directionality(
              textDirection: localeProvider.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox(),
            );
          },
          initialRoute: '/login',
          routes: {
            '/login': (_) => const HodooriLoginScreen(),
            '/': (_) => const LoginPage(),
            ViewStudent.routeName: (_) => const ViewStudent(),
            DepartmentSettingsPage.routeName: (_) =>
                const DepartmentSettingsPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == GroupsScreen.routeName) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const GroupsScreen(),
              );
            }
            if (settings.name == StudentsScreen.routeName) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const StudentsScreen(),
              );
            }
            if (settings.name == TeacherProfilePage.routeName) {
              final args = settings.arguments as Map<String, String>?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => TeacherProfilePage(
                  teacherId: args?['teacherId'],
                  teacherEmail: args?['teacherEmail'],
                ),
              );
            }
            if (settings.name == StudentsPage.routeName) {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => StudentsPage(
                  studentDocumentId: args?['studentDocumentId'] as String?,
                  studentEmail: args?['studentEmail'] as String?,
                  selfViewOnly: args?['selfViewOnly'] as bool? ?? false,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}

// ==================== HODOORI LOGIN SCREEN ====================

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

  Widget _destinationForProfile(AppUserProfile profile) {
    if (profile.role == 'Department') return const DepartmentDashboard();
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _destinationForProfile(profile),
        ),
      );
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _destinationForProfile(profile),
            ),
          );
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _destinationForProfile(profile),
            ),
          );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFEEF2F7)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: SingleChildScrollView(
              child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 1, child: _buildLogoSection()),
          const SizedBox(width: 60),
          Expanded(flex: 1, child: _buildLoginCard()),
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
          const SizedBox(height: 50),
          _buildLoginCard(),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) => Transform.scale(
            scale: 0.8 + value * 0.2,
            child: Opacity(opacity: value, child: child),
          ),
          child: SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(painter: _HodooriLogoPainter()),
          ),
        ),
        const SizedBox(height: 30),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1400),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          ),
          child: const Text(
            'Hodoori',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F3A93),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Smart University Attendance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F3A93).withOpacity(0.12),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            padding: const EdgeInsets.all(40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F3A93),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enter your credentials',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Role selector
                  _buildRoleSelector(),
                  const SizedBox(height: 30),

                  // Email
                  _buildInputLabel('Email'),
                  const SizedBox(height: 8),
                  _buildEmailField(),
                  const SizedBox(height: 16),

                  // Password
                  _buildInputLabel('Password'),
                  const SizedBox(height: 8),
                  _buildPasswordField(),
                  const SizedBox(height: 16),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isSigningIn ? null : _showForgotPasswordDialog,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(
                              0xFF2563EB,
                            ).withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login button
                  _buildLoginButton(),
                  const SizedBox(height: 20),

                  // Sign up
                  Center(
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildRoleSelector() {
    final roles = ['Student', 'Teacher', 'Department'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2563EB), Color(0xFF1F3A93)],
                        )
                      : const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 12,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'your.email@university.edu',
          hintStyle: TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.mail_outline,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: '••••••••',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFC4B5FD)),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _passwordVisible = !_passwordVisible),
            child: Icon(
              _passwordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF9CA3AF),
              size: 18,
            ),
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1F3A93)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _isSigningIn
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 15,
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

// ── LOGO PAINTER ─────────────────────────────────────────────────────
class _HodooriLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.82),
        width: size.width * 0.72,
        height: size.height * 0.14,
      ),
      Paint()
        ..color = const Color(0xFF2563EB).withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
    );

    // Graduation cap
    final capPath = Path()
      ..moveTo(cx, size.height * 0.04)
      ..lineTo(size.width * 0.92, size.height * 0.30)
      ..lineTo(cx, size.height * 0.44)
      ..lineTo(size.width * 0.08, size.height * 0.30)
      ..close();

    canvas.drawPath(
      capPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4DAEF0), Color(0xFF2176CC)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.44)),
    );

    canvas.drawPath(
      capPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1.5,
    );

    // Book left page
    final bookTop = size.height * 0.37;
    final bookBottom = size.height * 0.78;
    final bookLeft = size.width * 0.14;
    final bookRight = size.width * 0.86;

    canvas.drawPath(
      Path()
        ..moveTo(cx, bookTop + 6)
        ..lineTo(bookLeft, bookTop + size.height * 0.06)
        ..lineTo(bookLeft, bookBottom)
        ..quadraticBezierTo(cx, bookBottom - 10, cx, bookBottom)
        ..close(),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B9EE8), Color(0xFF1A6EC4)],
            ).createShader(
              Rect.fromLTWH(
                bookLeft,
                bookTop,
                cx - bookLeft,
                bookBottom - bookTop,
              ),
            ),
    );

    // Book right page
    canvas.drawPath(
      Path()
        ..moveTo(cx, bookTop + 6)
        ..lineTo(bookRight, bookTop + size.height * 0.06)
        ..lineTo(bookRight, bookBottom)
        ..quadraticBezierTo(cx, bookBottom - 10, cx, bookBottom)
        ..close(),
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4DAEF0), Color(0xFF2176CC)],
            ).createShader(
              Rect.fromLTWH(cx, bookTop, bookRight - cx, bookBottom - bookTop),
            ),
    );

    // Spine
    canvas.drawLine(
      Offset(cx, bookTop + 6),
      Offset(cx, bookBottom),
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..strokeWidth = 2,
    );

    // Checkmark
    canvas.drawPath(
      Path()
        ..moveTo(cx - size.width * 0.18, size.height * 0.60)
        ..lineTo(cx - size.width * 0.04, size.height * 0.73)
        ..lineTo(cx + size.width * 0.22, size.height * 0.49),
      Paint()
        ..color = Colors.white
        ..strokeWidth = size.width * 0.062
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // Hodoori pill
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.91),
        width: size.width * 0.68,
        height: size.height * 0.12,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      pillRect,
      Paint()
        ..shader =
            const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1743A0)],
            ).createShader(
              Rect.fromCenter(
                center: Offset(cx, size.height * 0.91),
                width: size.width * 0.68,
                height: size.height * 0.12,
              ),
            ),
    );

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Hodoori',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, size.height * 0.91 - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
