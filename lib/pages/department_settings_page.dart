// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/pages/departement/common_widgets.dart';

class DepartmentSettingsPage extends StatefulWidget {
  const DepartmentSettingsPage({super.key});

  static const String routeName = '/department/settings';

  @override
  State<DepartmentSettingsPage> createState() => _DepartmentSettingsPageState();
}

class _DepartmentSettingsPageState extends State<DepartmentSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _displayNameController;
  late TextEditingController _universityNameController;

  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedAcademicYear = '2024-2025';
  String _selectedSemester = 'S1';

  bool _isLoadingProfile = false;
  bool _isLoadingDepartment = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _universityNameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _universityNameController.dispose();
    super.dispose();
  }

  // ── Firebase Load ─────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('user_profiles')
            .doc(user.uid)
            .get();
        if (!mounted) return;
        if (doc.exists) {
          final data = doc.data() ?? {};
          setState(() {
            _displayNameController.text = data['displayName'] ?? '';
            _universityNameController.text = data['universityName'] ?? '';
            _selectedAcademicYear = data['academicYear'] ?? '2024-2025';
            _selectedSemester = data['semester'] ?? 'S1';
            _selectedLanguage = data['language'] ?? 'English';
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error loading profile: $e');
    }
  }

  // ── Save Profile ──────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoadingProfile = true);
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
          'language': _selectedLanguage,
          'notificationsEnabled': _notificationsEnabled,
        }, SetOptions(merge: true));
        if (!mounted) return;
        _showSuccess('Profile saved successfully!');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ── Save Department Settings ──────────────────────────────────────

  Future<void> _saveDepartmentSettings() async {
    try {
      setState(() => _isLoadingDepartment = true);
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'universityName': _universityNameController.text.trim(),
          'academicYear': _selectedAcademicYear,
          'semester': _selectedSemester,
        }, SetOptions(merge: true));
        if (!mounted) return;
        _showSuccess('Department settings saved!');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error saving settings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDepartment = false);
    }
  }

  // ── Change Email ──────────────────────────────────────────────────

  Future<void> _changeEmail() async {
    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Email',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmailController,
              decoration: const InputDecoration(
                labelText: 'New Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final email = newEmailController.text.trim();
              final password = currentPasswordController.text;
              Navigator.pop(dialogContext);
              await _performChangeEmail(email, password);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    newEmailController.dispose();
    currentPasswordController.dispose();
  }

  Future<void> _performChangeEmail(String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user?.email == null) return;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.verifyBeforeUpdateEmail(newEmail);
      if (!mounted) return;
      _showSuccess('Verification link sent! Check your new email inbox.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Error changing email.');
    } catch (e) {
      if (!mounted) return;
      _showError('Error changing email: $e');
    }
  }

  // ── Change Password ───────────────────────────────────────────────

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final current = currentPasswordController.text;
              final newPass = newPasswordController.text;
              final confirm = confirmPasswordController.text;
              Navigator.pop(dialogContext);
              await _performChangePassword(current, newPass, confirm);
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _performChangePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }
    if (newPassword.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    try {
      final user = _auth.currentUser;
      if (user?.email == null) return;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      if (!mounted) return;
      _showSuccess('Password changed successfully!');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Error changing password.');
    } catch (e) {
      if (!mounted) return;
      _showError('Error changing password: $e');
    }
  }

  // ── Snackbars ─────────────────────────────────────────────────────

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, 'Settings'),
      drawer: departmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? 'Department Admin',
                          style: const TextStyle(
                            color: Colors.white70,
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

            // ── Account Settings ────────────────────────────────────
            _sectionTitle('Account Settings', Icons.person_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _label('Display Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: _inputDeco(
                    'Enter your display name',
                    Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                _label('Email'),
                const SizedBox(height: 8),
                TextField(
                  enabled: false,
                  controller: TextEditingController(
                    text: user?.email ?? 'No email',
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _outlineButton(
                        label: 'Change Email',
                        icon: Icons.email,
                        color: const Color(0xFF2563EB),
                        onTap: _changeEmail,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineButton(
                        label: 'Change Password',
                        icon: Icons.lock_outline,
                        color: const Color(0xFF7C3AED),
                        onTap: _changePassword,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _saveButton(
                  label: 'Save Profile',
                  isLoading: _isLoadingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── App Settings ────────────────────────────────────────
            _sectionTitle('App Settings', Icons.tune_outlined),
            const SizedBox(height: 10),
            _card(
              children: [
                Row(
                  children: [
                    _iconBox(Icons.language, const Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Language',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(10),
                      items: ['English', 'French', 'Arabic']
                          .map(
                            (l) => DropdownMenuItem(value: l, child: Text(l)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLanguage = v!),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _iconBox(
                      Icons.notifications_outlined,
                      const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Receive alerts and updates',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                      thumbColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF2563EB)
                            : Colors.grey,
                      ),
                      trackColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF2563EB).withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    _iconBox(Icons.dark_mode_outlined, const Color(0xFF374151)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Switch to dark theme',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _darkModeEnabled,
                      onChanged: (v) => setState(() => _darkModeEnabled = v),
                      thumbColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF2563EB)
                            : Colors.grey,
                      ),
                      trackColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? const Color(0xFF2563EB).withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Department Settings ─────────────────────────────────
            _sectionTitle(
              'Department Settings',
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),
            _card(
              children: [
                _label('University Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _universityNameController,
                  decoration: _inputDeco(
                    'Enter university name',
                    Icons.school_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Academic Year'),
                          const SizedBox(height: 6),
                          _dropdown(
                            value: _selectedAcademicYear,
                            items: ['2024-2025', '2025-2026', '2026-2027'],
                            onChanged: (v) =>
                                setState(() => _selectedAcademicYear = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Semester'),
                          const SizedBox(height: 6),
                          _dropdown(
                            value: _selectedSemester,
                            items: ['S1', 'S2'],
                            onChanged: (v) =>
                                setState(() => _selectedSemester = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _saveButton(
                  label: 'Save Department Settings',
                  isLoading: _isLoadingDepartment,
                  onPressed: _saveDepartmentSettings,
                  color: const Color(0xFF004AC6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── About ───────────────────────────────────────────────
            _sectionTitle('About', Icons.info_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _infoRow('App Version', '1.0.0'),
                const Divider(height: 20),
                _infoRow('Build', 'Hodoori Smart Attendance'),
                const Divider(height: 20),
                _infoRow('Developer', 'Academic Team'),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: departmentBottomNav(context, 3),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(10),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    Color color = const Color(0xFF2563EB),
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
