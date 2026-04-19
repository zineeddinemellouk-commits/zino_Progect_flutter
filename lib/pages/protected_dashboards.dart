import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/services/role_manager.dart';
import 'package:test/services/auth_service.dart';
import 'package:test/widgets/role_protected_screen.dart';

/// Protected Student Dashboard
/// Only accessible to users with 'student' role
class StudentDashboard extends RoleProtectedScreen {
  const StudentDashboard({super.key});

  @override
  UserRole get requiredRole => UserRole.student;

  @override
  Widget buildContent(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    final userId = roleManager.currentUserId;
    final email = roleManager.currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Profile'),
                onTap: () {
                  // Navigate to profile
                },
              ),
              PopupMenuItem(
                child: const Text('Settings'),
                onTap: () {
                  // Navigate to settings
                },
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await context.read<AuthService>().logout(
                    roleManager: context.read<RoleManager>(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: $email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'User ID: $userId',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Attendance',
                    subtitle: 'View your attendance',
                    onTap: () {
                      // Navigate to attendance
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.assignment_late,
                    title: 'Absences',
                    subtitle: 'Your absence records',
                    onTap: () {
                      // Navigate to absences
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.description,
                    title: 'Justifications',
                    subtitle: 'Submit justifications',
                    onTap: () {
                      // Navigate to justifications
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Unread messages',
                    onTap: () {
                      // Navigate to notifications
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Role-Based Access Info
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '✅ You are authenticated as a Student.\n'
                          'You can only access student-specific features.',
                          style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Protected Teacher Dashboard
/// Only accessible to users with 'teacher' role
class TeacherDashboard extends RoleProtectedScreen {
  const TeacherDashboard({super.key});

  @override
  UserRole get requiredRole => UserRole.teacher;

  @override
  Widget buildContent(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    final email = roleManager.currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Profile'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Text('Settings'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await context.read<AuthService>().logout(
                    roleManager: context.read<RoleManager>(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, Teacher!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: $email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Teaching Tools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildTeacherFeatures(context),
              const SizedBox(height: 24),
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '✅ You are authenticated as a Teacher.\n'
                          'You can only access teacher-specific features.',
                          style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  Widget _buildTeacherFeatures(BuildContext context) {
    return Column(
      children: [
        _buildFeatureTile(
          context,
          icon: Icons.people,
          title: 'Manage Students',
          subtitle: 'View and manage student information',
        ),
        _buildFeatureTile(
          context,
          icon: Icons.calendar_today,
          title: 'Attendance',
          subtitle: 'Record and track attendance',
        ),
        _buildFeatureTile(
          context,
          icon: Icons.assignment,
          title: 'Class Schedule',
          subtitle: 'View and update class schedule',
        ),
        _buildFeatureTile(
          context,
          icon: Icons.report,
          title: 'Reports',
          subtitle: 'Generate attendance reports',
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}

/// Protected Department Dashboard
/// Only accessible to users with 'department' role
class DepartmentDashboard extends RoleProtectedScreen {
  const DepartmentDashboard({super.key});

  @override
  UserRole get requiredRole => UserRole.department;

  @override
  Widget buildContent(BuildContext context) {
    final roleManager = context.read<RoleManager>();
    final email = roleManager.currentUserEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Dashboard'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Settings'),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () async {
                  await context.read<AuthService>().logout(
                    roleManager: context.read<RoleManager>(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department Admin',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: $email',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Administration Tools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildAdminFeatures(context),
              const SizedBox(height: 24),
              Card(
                color: Colors.purple.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '✅ You are authenticated as Department Admin.\n'
                          'Full system access available.',
                          style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  Widget _buildAdminFeatures(BuildContext context) {
    return Column(
      children: [
        _buildAdminTile(
          context,
          icon: Icons.people,
          title: 'Manage Users',
          subtitle: 'Create and manage all users',
        ),
        _buildAdminTile(
          context,
          icon: Icons.school,
          title: 'Manage Teachers',
          subtitle: 'Assign levels, groups, and subjects',
        ),
        _buildAdminTile(
          context,
          icon: Icons.group,
          title: 'Manage Students',
          subtitle: 'View all students and assignments',
        ),
        _buildAdminTile(
          context,
          icon: Icons.analytics,
          title: 'System Reports',
          subtitle: 'Generate comprehensive reports',
        ),
        _buildAdminTile(
          context,
          icon: Icons.security,
          title: 'Security Settings',
          subtitle: 'Configure system security',
        ),
        _buildAdminTile(
          context,
          icon: Icons.settings,
          title: 'System Settings',
          subtitle: 'Configure system parameters',
        ),
      ],
    );
  }

  Widget _buildAdminTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
