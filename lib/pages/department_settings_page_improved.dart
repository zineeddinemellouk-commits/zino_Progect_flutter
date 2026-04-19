import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:test/l10n/app_localizations.dart';
import 'package:test/l10n/language_provider.dart';
import 'package:test/l10n/language_service.dart';
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
  final LanguageService _languageService = LanguageService();

  late TextEditingController _displayNameController;
  late TextEditingController _universityNameController;

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

  /// Load user profile from Firestore
  /// Falls back to local cache if offline
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
          final savedLanguage = data['language'] as String? ?? 'en';

          setState(() {
            _displayNameController.text = data['displayName'] ?? '';
            _universityNameController.text = data['universityName'] ?? '';
            _selectedAcademicYear = data['academicYear'] ?? '2024-2025';
            _selectedSemester = data['semester'] ?? 'S1';
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
          });

          // Update LanguageProvider with saved language
          if (mounted && LanguageService.isSupported(savedLanguage)) {
            context.read<LanguageProvider>().setLanguage(savedLanguage);
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error loading profile: $e');
    }
  }

  /// Save profile (display name, notifications, language preference)
  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isLoadingProfile = true);
      final user = _auth.currentUser;
      if (user != null) {
        final currentLanguageCode = context
            .read<LanguageProvider>()
            .languageCode;

        // Save to Firestore
        await _firestore.collection('user_profiles').doc(user.uid).set({
          'displayName': _displayNameController.text.trim(),
          'language': currentLanguageCode,
          'notificationsEnabled': _notificationsEnabled,
        }, SetOptions(merge: true));

        // Also save to SharedPreferences for faster access
        await _languageService.saveLanguage(currentLanguageCode);

        if (!mounted) return;
        _showSuccess(l10n.profileSavedSuccess);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  /// Save department settings (university, academic year, semester)
  Future<void> _saveDepartmentSettings() async {
    final l10n = AppLocalizations.of(context);
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
        _showSuccess(l10n.departmentSettingsSaved);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Error saving settings: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDepartment = false);
    }
  }

  /// Handle email change with reauthentication
  Future<void> _changeEmail() async {
    final l10n = AppLocalizations.of(context);
    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.changeEmail,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newEmailController,
              decoration: InputDecoration(
                labelText: l10n.newEmail,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
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
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    newEmailController.dispose();
    currentPasswordController.dispose();
  }

  Future<void> _performChangeEmail(String newEmail, String password) async {
    final l10n = AppLocalizations.of(context);
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
      _showSuccess(l10n.verificationEmailSent);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Error changing email.');
    } catch (e) {
      if (!mounted) return;
      _showError('Error changing email: $e');
    }
  }

  /// Handle password change
  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.changePassword,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: l10n.currentPassword,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
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
            child: Text(l10n.confirm),
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
    final l10n = AppLocalizations.of(context);
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
      _showSuccess(l10n.passwordChangedSuccess);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'Error changing password.');
    } catch (e) {
      if (!mounted) return;
      _showError('Error changing password: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = context.watch<LanguageProvider>();
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, l10n.settings),
      drawer: departmentDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
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
                          l10n.settings,
                          style: const TextStyle(
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

            // ── Account Settings ──────────────────────────────────
            _sectionTitle(l10n.accountSettings, Icons.person_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _label(l10n.displayName),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: _inputDeco(
                    l10n.enterDisplayName,
                    Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 14),
                _label(l10n.email),
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
                        label: l10n.changeEmail,
                        icon: Icons.email,
                        color: const Color(0xFF2563EB),
                        onTap: _changeEmail,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _outlineButton(
                        label: l10n.changePassword,
                        icon: Icons.lock_outline,
                        color: const Color(0xFF7C3AED),
                        onTap: _changePassword,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _saveButton(
                  label: l10n.saveProfile,
                  isLoading: _isLoadingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── App Settings ──────────────────────────────────────
            _sectionTitle(l10n.appSettings, Icons.tune_outlined),
            const SizedBox(height: 10),
            _card(
              children: [
                // ── Language (INSTANT SWITCH) ───────────────────────
                Row(
                  children: [
                    _iconBox(Icons.language, const Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.language,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    // Language buttons — instant switch + saves on profile save
                    Row(
                      children: [
                        _langButton(
                          label: 'EN',
                          isSelected: languageProvider.languageCode == 'en',
                          onTap: () {
                            context.read<LanguageProvider>().setEnglish();
                          },
                        ),
                        const SizedBox(width: 6),
                        _langButton(
                          label: 'FR',
                          isSelected: languageProvider.languageCode == 'fr',
                          onTap: () {
                            context.read<LanguageProvider>().setFrench();
                          },
                        ),
                        const SizedBox(width: 6),
                        _langButton(
                          label: 'ع',
                          isSelected: languageProvider.languageCode == 'ar',
                          onTap: () {
                            context.read<LanguageProvider>().setArabic();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),

                // ── Notifications ────────────────────────────────────
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
                            l10n.notifications,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            l10n.receiveAlerts,
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

                // ── Dark Mode ─────────────────────────────────────────
                Row(
                  children: [
                    _iconBox(Icons.dark_mode_outlined, const Color(0xFF374151)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.darkMode,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            l10n.switchToDarkTheme,
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

            // ── Department Settings ───────────────────────────────
            _sectionTitle(
              l10n.departmentSettings,
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 10),
            _card(
              children: [
                _label(l10n.universityName),
                const SizedBox(height: 8),
                TextField(
                  controller: _universityNameController,
                  decoration: _inputDeco(
                    l10n.enterUniversityName,
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
                          _label(l10n.academicYear),
                          const SizedBox(height: 6),
                          _dropdown(
                            value: _selectedAcademicYear,
                            items: const [
                              '2024-2025',
                              '2025-2026',
                              '2026-2027',
                            ],
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
                          _label(l10n.semester),
                          const SizedBox(height: 6),
                          _dropdown(
                            value: _selectedSemester,
                            items: const ['S1', 'S2'],
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
                  label: l10n.saveDepartmentSettings,
                  isLoading: _isLoadingDepartment,
                  onPressed: _saveDepartmentSettings,
                  color: const Color(0xFF004AC6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── About ─────────────────────────────────────────────
            _sectionTitle(l10n.about, Icons.info_outline),
            const SizedBox(height: 10),
            _card(
              children: [
                _infoRow(l10n.appVersion, '1.0.0'),
                const Divider(height: 20),
                _infoRow(l10n.build, 'Hodoori Smart Attendance'),
                const Divider(height: 20),
                _infoRow(l10n.developer, 'Academic Team'),
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

  /// Language selector button with instant feedback
  Widget _langButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
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
