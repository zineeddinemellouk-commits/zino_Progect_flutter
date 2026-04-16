import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/widgets/student_info_card.dart';

class StudentsScreenArgs {
  const StudentsScreenArgs({required this.level, required this.group});

  final LevelModel level;
  final GroupModel group;
}

class StudentsScreen extends StatelessWidget {
  const StudentsScreen({super.key});

  static const String routeName = '/students/list';

  Future<void> _showEditStudentDialog(
    BuildContext context,
    StudentsScreenArgs args,
    dynamic student,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditStudentDialog(student: student, args: args),
    );
  }

  Future<void> _confirmDeleteStudent(
    BuildContext context,
    dynamic student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete student?'),
          content: Text(
            'Delete ${student.fullName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<StudentManagementProvider>().deleteStudent(student.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete student: $e')),
      );
    }
  }

  Future<void> _showAddStudentDialog(
    BuildContext context,
    StudentsScreenArgs args,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddStudentDialog(args: args),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is! StudentsScreenArgs) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: departmentAppBar(context, 'Students'),
        drawer: departmentDrawer(context),
        body: Center(
          child: Text(
            'Unable to open students: invalid group data.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    final args = rawArgs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(
        context,
        'Students - ${args.level.name} / ${args.group.name}',
      ),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: context
                    .read<StudentManagementProvider>()
                    .watchStudentsByGroup(groupId: args.group.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load students. Please verify your connection.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  }

                  final students = snapshot.data ?? const [];

                  if (students.isEmpty) {
                    return Center(
                      child: Text(
                        'No students in this group yet. Tap + to add one.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${students.length} students found',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            return StudentInfoCard(
                              student: students[index],
                              fallbackGroupName: args.group.name,
                              onEdit: () => _showEditStudentDialog(
                                context,
                                args,
                                students[index],
                              ),
                              onDelete: () => _confirmDeleteStudent(
                                context,
                                students[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStudentDialog(context, args),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Student'),
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}

class _EditStudentDialog extends StatefulWidget {
  const _EditStudentDialog({required this.student, required this.args});

  final dynamic student;
  final StudentsScreenArgs args;

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _attendanceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.student.fullName);
    _emailController = TextEditingController(text: widget.student.email);
    _attendanceController = TextEditingController(
      text: widget.student.attendancePercentage.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Student'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _attendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Attendance %',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null) return 'Attendance must be a number';
                    if (parsed < 0 || parsed > 100) {
                      return 'Attendance must be between 0 and 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      await context.read<StudentManagementProvider>().updateStudent(
            id: widget.student.id,
            fullName: _nameController.text,
            email: _emailController.text,
            attendancePercentage: int.parse(
              _attendanceController.text.trim(),
            ),
            groupId: widget.args.group.id,
            classId: widget.student.classId,
            subjectIds: List<String>.from(widget.student.subjectIds),
            levelId: widget.args.level.id,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update student: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog({required this.args});

  final StudentsScreenArgs args;

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _attendanceController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _attendanceController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Student'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email is required';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm the password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _attendanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Attendance %',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    if (parsed == null) return 'Attendance must be a number';
                    if (parsed < 0 || parsed > 100) {
                      return 'Attendance must be between 0 and 100';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSaving = true);
    try {
      await context.read<StudentManagementProvider>().addStudent(
            fullName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            attendancePercentage: int.parse(
              _attendanceController.text.trim(),
            ),
            groupId: widget.args.group.id,
            levelId: widget.args.level.id,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add student: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
