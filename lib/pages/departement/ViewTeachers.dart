import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';

class ViewTeachers extends StatelessWidget {
  const ViewTeachers({super.key});

  static const String routeName = '/teachers/view';

  Future<void> _confirmDelete(
    BuildContext context,
    TeacherModel teacher,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete teacher?'),
          content: Text(
            'Delete ${teacher.fullName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<StudentManagementProvider>().deleteTeacher(teacher.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete teacher: $e')));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    TeacherModel teacher,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _EditTeacherDialog(teacher: teacher),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, 'View Teachers'),
      drawer: departmentDrawer(context),
      body: StreamBuilder<List<TeacherModel>>(
        stream: context.read<StudentManagementProvider>().watchTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Failed to load teachers: ${snapshot.error}'),
              ),
            );
          }

          final teachers = snapshot.data ?? const <TeacherModel>[];
          if (teachers.isEmpty) {
            return const Center(
              child: Text(
                'No teachers found.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  title: Text(
                    teacher.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${teacher.email}\nSubjects: ${teacher.subjectIds.length} • Groups: ${teacher.groupIds.length}',
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        onPressed: () => _showEditDialog(context, teacher),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context, teacher),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}

class _EditTeacherDialog extends StatefulWidget {
  const _EditTeacherDialog({required this.teacher});

  final TeacherModel teacher;

  @override
  State<_EditTeacherDialog> createState() => _EditTeacherDialogState();
}

class _EditTeacherDialogState extends State<_EditTeacherDialog> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final Set<String> _selectedSubjects;
  late final Set<String> _selectedGroupIds;
  final Map<String, String> _groupLevelIds = <String, String>{};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.teacher.fullName);
    _emailController = TextEditingController(text: widget.teacher.email);
    _selectedSubjects = <String>{...widget.teacher.subjectIds};
    _selectedGroupIds = <String>{...widget.teacher.groupIds};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Teacher'),
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
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Subjects',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<SubjectModel>>(
                  stream: context
                      .read<StudentManagementProvider>()
                      .watchSubjects(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }

                    final subjects = snapshot.data ?? const <SubjectModel>[];
                    if (subjects.isEmpty) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No subjects found.'),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subjects.map((subject) {
                        final selected = _selectedSubjects.contains(subject.id);
                        return FilterChip(
                          selected: selected,
                          label: Text(subject.name),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedSubjects.add(subject.id);
                              } else {
                                _selectedSubjects.remove(subject.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assigned Groups',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<LevelModel>>(
                  stream: context
                      .read<StudentManagementProvider>()
                      .watchLevels(),
                  builder: (context, levelSnapshot) {
                    final levels = levelSnapshot.data ?? const <LevelModel>[];
                    if (levelSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const LinearProgressIndicator();
                    }
                    if (levels.isEmpty) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('No levels found.'),
                      );
                    }

                    return Column(
                      children: levels.map((level) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.name,
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StreamBuilder<List<GroupModel>>(
                                stream: context
                                    .read<StudentManagementProvider>()
                                    .watchGroupsByLevel(levelId: level.id),
                                builder: (context, groupSnapshot) {
                                  final groups =
                                      groupSnapshot.data ??
                                      const <GroupModel>[];
                                  if (groupSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const LinearProgressIndicator();
                                  }
                                  if (groups.isEmpty) {
                                    return const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('No groups found.'),
                                    );
                                  }

                                  for (final group in groups) {
                                    _groupLevelIds.putIfAbsent(
                                      group.id,
                                      () => group.levelId,
                                    );
                                  }

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: groups.map((group) {
                                      final selected = _selectedGroupIds
                                          .contains(group.id);
                                      return FilterChip(
                                        selected: selected,
                                        label: Text(group.name),
                                        onSelected: (value) {
                                          setState(() {
                                            if (value) {
                                              _selectedGroupIds.add(group.id);
                                            } else {
                                              _selectedGroupIds.remove(
                                                group.id,
                                              );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
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
          onPressed: _isSaving
              ? null
              : () async {
                  if (_formKey.currentState?.validate() != true) return;

                  if (_selectedGroupIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Select at least one group.'),
                      ),
                    );
                    return;
                  }

                  final levelIds = _selectedGroupIds
                      .map((groupId) => _groupLevelIds[groupId])
                      .whereType<String>()
                      .map((levelId) => levelId.trim())
                      .where((levelId) => levelId.isNotEmpty)
                      .toSet()
                      .toList();

                  setState(() => _isSaving = true);
                  try {
                    await context
                        .read<StudentManagementProvider>()
                        .updateTeacher(
                          id: widget.teacher.id,
                          fullName: _nameController.text,
                          email: _emailController.text,
                          subjectIds: _selectedSubjects.toList(),
                          levelIds: levelIds,
                          groupIds: _selectedGroupIds.toList(),
                        );

                    if (!mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teacher updated successfully.'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update teacher: $e')),
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
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
}
