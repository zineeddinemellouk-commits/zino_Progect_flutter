import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';

class ViewSubjects extends StatelessWidget {
  const ViewSubjects({super.key});

  static const String routeName = '/subjects/view';

  Future<void> _confirmDelete(
    BuildContext context,
    SubjectModel subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete subject?'),
          content: Text(
            'Delete ${subject.name}? This action cannot be undone.',
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
      await context.read<StudentManagementProvider>().deleteSubject(subject.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete subject: $e')));
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    SubjectModel subject,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: subject.name);
    String selectedTeacherId = subject.teacherId;
    final selectedClasses = <String>{...subject.classIds};
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Subject'),
              content: SizedBox(
                width: 470,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Subject Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Subject name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<TeacherModel>>(
                          stream: context
                              .read<StudentManagementProvider>()
                              .watchTeachers(),
                          builder: (context, teacherSnapshot) {
                            final teachers =
                                teacherSnapshot.data ?? const <TeacherModel>[];
                            return DropdownButtonFormField<String>(
                              initialValue:
                                  teachers.any((t) => t.id == selectedTeacherId)
                                  ? selectedTeacherId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Teacher',
                                border: OutlineInputBorder(),
                              ),
                              items: teachers
                                  .map(
                                    (teacher) => DropdownMenuItem(
                                      value: teacher.id,
                                      child: Text(teacher.fullName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedTeacherId = value ?? '';
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Classes',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<List<ClassModel>>(
                          stream: context
                              .read<StudentManagementProvider>()
                              .watchClasses(),
                          builder: (context, classSnapshot) {
                            final classes =
                                classSnapshot.data ?? const <ClassModel>[];
                            if (classSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (classes.isEmpty) {
                              return const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('No classes found.'),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: classes.map((item) {
                                final selected = selectedClasses.contains(
                                  item.id,
                                );
                                return FilterChip(
                                  label: Text(item.name),
                                  selected: selected,
                                  onSelected: (value) {
                                    setDialogState(() {
                                      if (value) {
                                        selectedClasses.add(item.id);
                                      } else {
                                        selectedClasses.remove(item.id);
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
                          if (formKey.currentState?.validate() != true) return;
                          if (selectedClasses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Select at least one class.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          try {
                            await context
                                .read<StudentManagementProvider>()
                                .updateSubject(
                                  id: subject.id,
                                  name: nameController.text,
                                  teacherId: selectedTeacherId,
                                  classIds: selectedClasses.toList(),
                                );

                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Subject updated successfully.'),
                                  ),
                                );
                              }
                            });
                          } catch (e) {
                            if (!context.mounted) return;
                            Navigator.of(dialogContext).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to update subject: $e'),
                                  ),
                                );
                              }
                            });
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

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, 'View Subjects'),
      drawer: departmentDrawer(context),
      body: StreamBuilder<List<SubjectModel>>(
        stream: context.read<StudentManagementProvider>().watchSubjects(),
        builder: (context, subjectSnapshot) {
          if (subjectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subjectSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Failed to load subjects: ${subjectSnapshot.error}',
                ),
              ),
            );
          }

          final subjects = subjectSnapshot.data ?? const <SubjectModel>[];
          if (subjects.isEmpty) {
            return const Center(
              child: Text(
                'No subjects found.',
                style: TextStyle(color: Color(0xFF667085)),
              ),
            );
          }

          return StreamBuilder<List<TeacherModel>>(
            stream: context.read<StudentManagementProvider>().watchTeachers(),
            builder: (context, teacherSnapshot) {
              final teachers = teacherSnapshot.data ?? const <TeacherModel>[];
              final teacherById = <String, TeacherModel>{
                for (final teacher in teachers) teacher.id: teacher,
              };

              return StreamBuilder<List<ClassModel>>(
                stream: context
                    .read<StudentManagementProvider>()
                    .watchClasses(),
                builder: (context, classSnapshot) {
                  final classes = classSnapshot.data ?? const <ClassModel>[];
                  final classById = <String, ClassModel>{
                    for (final item in classes) item.id: item,
                  };

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final teacherName =
                          teacherById[subject.teacherId]?.fullName ??
                          'Unassigned';
                      final classNames = subject.classIds
                          .map((id) => classById[id]?.name ?? id)
                          .toList();

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
                            subject.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Teacher: $teacherName\nClasses: ${classNames.join(', ')}',
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _showEditDialog(context, subject),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () =>
                                    _confirmDelete(context, subject),
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
              );
            },
          );
        },
      ),
      bottomNavigationBar: departmentBottomNav(context, 2),
    );
  }
}
