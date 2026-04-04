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

  Future<void> _showAddStudentDialog(
    BuildContext context,
    StudentsScreenArgs args,
  ) async {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final attendanceController = TextEditingController(text: '0');
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add new student'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final trimmed = value?.trim() ?? '';
                          if (trimmed.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(trimmed)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
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
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm the password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: attendanceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Attendance %',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null) {
                            return 'Attendance must be a number';
                          }
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
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() != true) {
                            return;
                          }

                          if (passwordController.text !=
                              confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            await context
                                .read<StudentManagementProvider>()
                                .addStudent(
                                  fullName: fullNameController.text,
                                  email: emailController.text,
                                  password: passwordController.text,
                                  attendancePercentage: int.parse(
                                    attendanceController.text.trim(),
                                  ),
                                  groupId: args.group.id,
                                  levelId: args.level.id,
                                );

                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Student added successfully.'),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to add student. Please check network and try again.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
