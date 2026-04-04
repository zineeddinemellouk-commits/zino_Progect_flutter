import 'package:flutter/material.dart';
import 'package:test/services/department_auth_service.dart';

class RoleHomePage extends StatelessWidget {
  const RoleHomePage({
    super.key,
    required this.role,
    required this.email,
    required this.displayName,
  });

  final String role;
  final String email;
  final String displayName;

  Future<void> _logout(BuildContext context) async {
    await DepartmentAuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004AC6),
        foregroundColor: Colors.white,
        title: Text('$role Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as $role',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Text(
                  'Email: $email',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Text(
                  role == 'Student'
                      ? 'Student access is ready. Add student features here.'
                      : 'Teacher access is ready. Add teacher features here.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
