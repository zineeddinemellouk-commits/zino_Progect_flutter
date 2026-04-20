// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/providers/locale_provider.dart';

class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  static const String routeName = '/student/settings';

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _displayNameController;

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
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
          'notificationsEnabled': _notificationsEnabled,
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FB),
        foregroundColor: const Color(0xFF1A1A1A),
        title: Text(
          context.tr('settings'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
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
                        Text(
                          context.tr('settings'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? context.tr('student'),
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

            // ── App Settings ────────────────────────────────────────
            _sectionTitle(context.tr('app_settings'), Icons.tune_outlined),
            const SizedBox(height: 10),
            _card(
              children: [
                // ── Language Selector ──────────────────────────────
                Consumer<LocaleProvider>(
                  builder: (context, localeProvider, _) => Column(
                    children: [
                      Row(
                        children: [
                          _iconBox(Icons.language, const Color(0xFF2563EB)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.tr('language'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          DropdownButton<String>(
                            value: localeProvider.languageCode,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(10),
                            items: LocaleProvider.languageOptions.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                await localeProvider.setLocale(value);
                                if (!context.mounted) return;
                                setState(() {});
                              }
                            },
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('notifications'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  context.tr('receive_alerts'),
                                  style: const TextStyle(
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
                          _iconBox(
                            Icons.dark_mode_outlined,
                            const Color(0xFF374151),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('dark_mode'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  context.tr('switch_dark_theme'),
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _darkModeEnabled,
                            onChanged: (v) =>
                                setState(() => _darkModeEnabled = v),
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
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── About ───────────────────────────────────────────────
            _sectionTitle(context.tr('about'), Icons.info_outline),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
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
