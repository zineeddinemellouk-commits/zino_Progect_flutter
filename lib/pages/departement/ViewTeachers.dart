import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/helpers/localization_helper.dart';

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
          title: Text(context.tr('delete')),
          content: Text(
            '${context.tr('delete')} ${teacher.fullName}? ${context.tr('error')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(context.tr('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<StudentManagementProvider>().deleteTeacher(teacher.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('success'))));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${context.tr('error')}: $e')));
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

  void _showTeacherDetailSheet(
    BuildContext context,
    TeacherModel teacher,
    List<SubjectModel> allSubjects,
  ) {
    final initials = teacher.fullName.isNotEmpty
        ? teacher.fullName[0].toUpperCase()
        : '';

    final assignedSubjects = allSubjects
        .where((subject) => teacher.subjectIds.contains(subject.id))
        .toList();

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
              const Color(0xFF7C3AED),
              const Color(0xFF5B21B6),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0, 0.25, 0.25],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with avatar and teacher info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(32),
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
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      teacher.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      teacher.email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
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
                    // Stats section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: const Color(0xFF7C3AED),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Subjects: ${teacher.subjectIds.length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Divider(height: 14),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.class_outlined,
                                color: const Color(0xFF2563EB),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Classes: ${teacher.groupIds.length}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Assigned Subjects section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'ASSIGNED SUBJECTS',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (assignedSubjects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'No subjects assigned',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: assignedSubjects.map((subject) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF7C3AED,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                subject.name,
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
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
                                _showEditDialog(context, teacher);
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Teacher'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(
                                  color: Color(0xFF7C3AED),
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
                                _confirmDelete(context, teacher);
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        toolbarHeight: 60,
        centerTitle: false,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          context.tr('teachers'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: departmentDrawer(context),
      body: StreamBuilder<List<SubjectModel>>(
        stream: context.read<StudentManagementProvider>().watchSubjects(),
        builder: (context, subjectSnapshot) {
          final allSubjects = subjectSnapshot.data ?? const <SubjectModel>[];

          return StreamBuilder<List<TeacherModel>>(
            stream: context.read<StudentManagementProvider>().watchTeachers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('${context.tr('error')}: ${snapshot.error}'),
                  ),
                );
              }

              final teachers = snapshot.data ?? const <TeacherModel>[];
              if (teachers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.manage_accounts_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No teachers yet',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your first teacher to get started',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teachers.length,
                itemBuilder: (context, index) {
                  final teacher = teachers[index];
                  final initials = teacher.fullName.isNotEmpty
                      ? teacher.fullName[0].toUpperCase()
                      : '';

                  return GestureDetector(
                    onTap: () =>
                        _showTeacherDetailSheet(context, teacher, allSubjects),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
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
                          // Purple accent bar
                          Container(
                            width: 4,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Name with avatar
                                  Row(
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF7C3AED,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            23,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Color(0xFF7C3AED),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          teacher.fullName,
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
                                  // Email
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          teacher.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Stats chips
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF7C3AED,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.menu_book_outlined,
                                              size: 12,
                                              color: const Color(0xFF7C3AED),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${teacher.subjectIds.length} Subjects',
                                              style: const TextStyle(
                                                color: Color(0xFF7C3AED),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.class_outlined,
                                              size: 12,
                                              color: const Color(0xFF2563EB),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${teacher.groupIds.length} Classes',
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _showEditDialog(context, teacher),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: Color(0xFF7C3AED),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () => _confirmDelete(context, teacher),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
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
      title: Text(context.tr('edit')),
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
                  decoration: InputDecoration(
                    labelText: context.tr('display_name'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return context.tr('field_required');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return context.tr('field_required');
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return context.tr('invalid_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: context.isRtl
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    context.tr('subjects'),
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
