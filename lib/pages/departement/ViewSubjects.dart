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
                                    content: Text(
                                      'Subject updated successfully.',
                                    ),
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
                                    content: Text(
                                      'Failed to update subject: $e',
                                    ),
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

  void _showSubjectDetailSheet(
    BuildContext context,
    SubjectModel subject,
    TeacherModel? teacher,
    List<ClassModel> assignedClasses,
  ) {
    final initials = subject.name.isNotEmpty
        ? subject.name[0].toUpperCase()
        : '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2563EB),
              const Color(0xFF004AC6),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0, 0.25, 0.25],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and subject info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subject.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignedClasses.length} class${assignedClasses.length != 1 ? 'es' : ''} assigned',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assigned Classes section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'ASSIGNED CLASSES',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (assignedClasses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'No classes assigned',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < assignedClasses.length;
                              i++
                            ) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.class_outlined,
                                      color: const Color(0xFF2563EB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            assignedClasses[i].name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            teacher?.fullName ?? 'Unassigned',
                                            style: TextStyle(
                                              color: teacher != null
                                                  ? Colors.grey[600]
                                                  : const Color(0xFFF59E0B),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < assignedClasses.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditDialog(context, subject);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Subject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                side: const BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(context, subject);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first subject to get started',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
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
                      final teacher = teacherById[subject.teacherId];
                      final teacherName = teacher?.fullName ?? 'Unassigned';
                      final classNames = subject.classIds
                          .map((id) => classById[id]?.name ?? id)
                          .toList();
                      final assignedClasses = subject.classIds
                          .map((id) => classById[id])
                          .whereType<ClassModel>()
                          .toList();
                      final initials = subject.name.isNotEmpty
                          ? subject.name[0].toUpperCase()
                          : '';

                      return GestureDetector(
                        onTap: () => _showSubjectDetailSheet(
                          context,
                          subject,
                          teacher,
                          assignedClasses,
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Blue accent bar
                              Container(
                                width: 4,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                ),
                              ),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF2563EB,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Center(
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              subject.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              teacherName,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.class_outlined,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              classNames.join(', '),
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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
