// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/pages/departement/common_widgets.dart';

class AddDepartmentAccountPage extends StatefulWidget {
  const AddDepartmentAccountPage({super.key});

  static const String routeName = '/department/add-account';

  @override
  State<AddDepartmentAccountPage> createState() =>
      _AddDepartmentAccountPageState();
}

class _AddDepartmentAccountPageState extends State<AddDepartmentAccountPage> {
  // ── Controllers ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────
  bool _isCreating = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // ── Services ───────────────────────────────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;


  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Validation Methods ─────────────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ── Error Handler ──────────────────────────────────────────────────

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or reset the password.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }

  String _getFirestoreErrorMessage(dynamic e) {
    if (e.toString().contains('permission')) {
      return 'Permission denied. Only department admins can create accounts.';
    }
    if (e.toString().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Error saving user profile. Please try again.';
  }

  // ── Show Loading Dialog ────────────────────────────────────────────

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Creating Account'),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ── Show Success Dialog ────────────────────────────────────────────

  void _showSuccessDialog(String name, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Department account created successfully!'),
            const SizedBox(height: 12),
            _infoRow('Name', name),
            const SizedBox(height: 8),
            _infoRow('Email', email),
            const SizedBox(height: 8),
            _infoRow('Role', 'Department Admin'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _clearForm();
            },
            child: const Text('Create Another'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // ── Show Error Dialog ──────────────────────────────────────────────

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ── Create Department Account ──────────────────────────────────────

  Future<void> _createAccount() async {
    if (_formKey.currentState?.validate() != true) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isCreating = true);
    _showLoadingDialog('Creating department account...');

    try {
      // Step 1: Create Firebase Auth user
      _hideLoadingDialog();
      _showLoadingDialog('Setting up authentication...');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Unable to create user account.',
        );
      }

      // Step 2: Create user_profile document
      _hideLoadingDialog();
      _showLoadingDialog('Creating user profile...');

      await _firestore.collection('user_profiles').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'department',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'unknown',
        'status': 'active',
      });

      // Step 3: Create department collection document
      _hideLoadingDialog();
      _showLoadingDialog('Creating department profile...');

      await _firestore.collection('department').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? 'unknown',
        'permissions': ['manage_students', 'manage_teachers', 'manage_subjects'],
        'status': 'active',
      });

      // Success
      _hideLoadingDialog();
      if (!mounted) return;

      _showSuccessDialog(name, email);

      // Log event
      print('✅ Department account created successfully');
      print('   UID: $uid');
      print('   Name: $name');
      print('   Email: $email');
    } on FirebaseAuthException catch (e) {
      _hideLoadingDialog();
      if (!mounted) return;
      _showErrorDialog(
        'Account Creation Failed',
        _getFirebaseErrorMessage(e),
      );
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
    } on FirebaseException catch (e) {
      _hideLoadingDialog();
      if (!mounted) return;
      _showErrorDialog(
        'Profile Creation Failed',
        _getFirestoreErrorMessage(e),
      );
      print('❌ Firestore Error: ${e.code} - ${e.message}');
    } catch (e) {
      _hideLoadingDialog();
      if (!mounted) return;
      _showErrorDialog(
        'Unexpected Error',
        'An unexpected error occurred: ${e.toString()}',
      );
      print('❌ Unexpected Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  // ── Clear Form ─────────────────────────────────────────────────────

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _formKey.currentState?.reset();
  }

  // ── Build UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, 'Add Department Account'),
      drawer: departmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Card ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create New Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add a new department administrator',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Form Card ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Name Field ────────────────────────────────
                    _buildLabel('Display Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      validator: _validateName,
                      decoration: _buildInputDecoration(
                        'Enter full name',
                        Icons.person_outline,
                      ),
                      keyboardType: TextInputType.name,
                      enabled: !_isCreating,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),

                    // ── Email Field ───────────────────────────────
                    _buildLabel('Email Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      decoration: _buildInputDecoration(
                        'Enter email address',
                        Icons.email_outlined,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_isCreating,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 18),

                    // ── Password Field ────────────────────────────
                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      onToggleVisibility: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      showPassword: _showPassword,
                      hintText: 'Enter password (min 8 chars, uppercase, lowercase, number)',
                    ),
                    const SizedBox(height: 10),
                    _buildPasswordRequirements(),
                    const SizedBox(height: 18),

                    // ── Confirm Password Field ────────────────────
                    _buildLabel('Confirm Password'),
                    const SizedBox(height: 8),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      onToggleVisibility: () {
                        setState(() =>
                            _showConfirmPassword = !_showConfirmPassword);
                      },
                      showPassword: _showConfirmPassword,
                      hintText: 'Re-enter password',
                    ),
                    const SizedBox(height: 24),

                    // ── Buttons ────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isCreating ? null : _clearForm,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isCreating ? null : _createAccount,
                            icon: _isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: Text(
                              _isCreating ? 'Creating...' : 'Create Account',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF004AC6),
                              disabledBackgroundColor:
                                  const Color(0xFF004AC6).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Info Section ───────────────────────────────────────
            _buildInfoCard(
              title: 'Account Details',
              icon: Icons.info_outline,
              items: [
                'Role: Department Admin',
                'Permissions: Manage students, teachers, subjects',
                'Status: Active automatically',
              ],
            ),
            const SizedBox(height: 12),

            // ── Password Requirements Info ─────────────────────────
            _buildInfoCard(
              title: 'Password Requirements',
              icon: Icons.security_outlined,
              items: [
                'At least 8 characters long',
                'Contains uppercase letter (A-Z)',
                'Contains lowercase letter (a-z)',
                'Contains number (0-9)',
              ],
            ),
            const SizedBox(height: 12),

            // ── Important Note ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF59E0B),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Share the email and password with the new admin securely. '
                      'They can change the password after first login.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: departmentBottomNav(context, 0),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF004AC6),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    required VoidCallback onToggleVisibility,
    required bool showPassword,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: !showPassword,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF9CA3AF),
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF004AC6),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
      enabled: !_isCreating,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    final hasLength = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildRequirementRow('At least 8 characters', hasLength),
          _buildRequirementRow('One uppercase letter (A-Z)', hasUpper),
          _buildRequirementRow('One lowercase letter (a-z)', hasLower),
          _buildRequirementRow('One number (0-9)', hasNumber),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: met ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? Colors.green : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF004AC6), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF004AC6), size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
