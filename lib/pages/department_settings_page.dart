// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/main.dart';
import 'package:test/services/department_auth_service.dart';

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
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr('error_loading_profile'));
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
        }, SetOptions(merge: true));
        if (!mounted) return;
        _showSuccess(context.tr('profile_saved_success'));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr('error_saving_profile')}: $e');
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
        _showSuccess(context.tr('settings_saved_success'));
      }
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr('error_saving_settings')}: $e');
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
        title: Text(
          dialogContext.tr('change_email'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmailController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('new_email'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('current_password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.tr('cancel')),
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
            child: Text(dialogContext.tr('confirm')),
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
      _showSuccess(context.tr('verification_link_sent'));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? context.tr('error_changing_email'));
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr('error_changing_email')}: $e');
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
        title: Text(
          dialogContext.tr('change_password'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('current_password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('new_password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('confirm_password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.tr('cancel')),
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
            child: Text(dialogContext.tr('confirm')),
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
      _showError(context.tr('passwords_not_match'));
      return;
    }
    if (newPassword.length < 6) {
      _showError(context.tr('password_min_length'));
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
      _showSuccess(context.tr('password_changed'));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? context.tr('error_changing_password'));
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr('error_changing_password')}: $e');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────

  Future<void> _logout() async {
    try {
      await DepartmentAuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr('error_logout')}: $e');
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

  // ── Logout ────────────────────────────────────────────────────────

  Future<void> _logoutFromDepartment(BuildContext context) async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HodooriLoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showError('${context.tr("logout_error")}: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // Extract first 2 letters of display name for avatar
    String displayName = _displayNameController.text.isNotEmpty
        ? _displayNameController.text
        : (user?.email ?? '').split('@')[0];
    String initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase().padRight(2, '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(
        context,
        context.tr('settings'),
        customLeading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: departmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Avatar ─────────────────────────────────
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
                  // Avatar with initials
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
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
            _sectionTitle(context.tr('account_settings'), Icons.person_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _label(context.tr('display_name')),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: _inputDeco(
                    context.tr('enter_display_name'),
                    Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                _label(context.tr('current_email')),
                const SizedBox(height: 8),
                TextField(
                  enabled: false,
                  controller: TextEditingController(
                    text: user?.email ?? context.tr('current_email'),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                        label: context.tr('change_email'),
                        icon: Icons.email,
                        color: const Color(0xFF2563EB),
                        onTap: _changeEmail,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineButton(
                        label: context.tr('change_password'),
                        icon: Icons.lock_outline,
                        color: const Color(0xFF7C3AED),
                        onTap: _changePassword,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _saveButton(
                  label: context.tr('save_profile'),
                  isLoading: _isLoadingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Department Settings ─────────────────────────────────
            _sectionTitle(
              context.tr('department_settings'),
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),
            _card(
              children: [
                _label(context.tr('university_name')),
                const SizedBox(height: 8),
                TextField(
                  controller: _universityNameController,
                  decoration: _inputDeco(
                    context.tr('enter_university_name'),
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
                          _label(context.tr('academic_year')),
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
                          _label(context.tr('semester')),
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
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoadingDepartment
                        ? null
                        : _saveDepartmentSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoadingDepartment
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.tr('save_department_settings'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── About ───────────────────────────────────────────────
            _sectionTitle('About Hodoori', Icons.info_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _infoRow(context.tr('app_version'), '1.0.0'),
                const Divider(height: 20),
                _infoRow(
                  context.tr('build'),
                  context.tr('hodoori_smart_attendance'),
                ),
                const Divider(height: 20),
                _infoRow(context.tr('developer'), context.tr('academic_team')),
              ],
            ),
            const SizedBox(height: 24),

            // ── Sign Out ────────────────────────────────────────────
            _card(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logoutFromDepartment(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
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

  Widget _sectionTitle(String title, IconData icon, {Color? color}) {
    final textColor = color ?? const Color(0xFF2563EB);
    return Row(
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      prefixIcon: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        size: 20,
      ),
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        borderRadius: BorderRadius.circular(12),
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
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
