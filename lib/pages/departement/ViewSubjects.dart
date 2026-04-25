import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';

class ViewSubjects extends StatefulWidget {
  const ViewSubjects({super.key});

  static const String routeName = '/subjects/view';

  @override
  State<ViewSubjects> createState() => _ViewSubjectsState();
}

class _ViewSubjectsState extends State<ViewSubjects> {
  String?
  selectedSection; // null = Level 1 (sections), non-null = Level 2 (subjects in section)

  // Helper to extract section from class name (e.g., "L1 - A" -> "L1")
  String _extractSection(String className) {
    if (className.contains(' - ')) {
      return className.split(' - ')[0];
    }
    return className;
  }

  // Get all unique sections from classes
  Set<String> _getAllSections(List<ClassModel> classes) {
    return {for (final cls in classes) _extractSection(cls.name)};
  }

  // Get subject count for a section
  int _getSubjectCountForSection(
    List<SubjectModel> subjects,
    List<ClassModel> classes,
    String section,
  ) {
    final sectionClasses = classes
        .where((cls) => _extractSection(cls.name) == section)
        .toList();
    final classIds = {for (final cls in sectionClasses) cls.id};
    return subjects
        .where(
          (subject) =>
              subject.classIds.any((classId) => classIds.contains(classId)),
        )
        .length;
  }

  // Get subjects for a specific section
  List<SubjectModel> _getSubjectsForSection(
    List<SubjectModel> subjects,
    List<ClassModel> classes,
    String section,
  ) {
    final sectionClasses = classes
        .where((cls) => _extractSection(cls.name) == section)
        .toList();
    final classIds = {for (final cls in sectionClasses) cls.id};
    return subjects
        .where(
          (subject) =>
              subject.classIds.any((classId) => classIds.contains(classId)),
        )
        .toList();
  }

  // Determine if section is Licence or Master
  String _getSectionType(String section) {
    return section.startsWith('M') ? 'Master' : 'Licence';
  }

  // Determine section color (blue for Licence, purple for Master)
  Color _getSectionColor(String section) {
    return section.startsWith('M')
        ? const Color(0xFF7C3AED)
        : const Color(0xFF2563EB);
  }

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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.8,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          // Header with gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Edit Subject',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject Name Field
                                Text(
                                  'Subject Name',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter subject name',
                                    fillColor: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    filled: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF2563EB),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Subject name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Teacher Field
                                Text(
                                  'Teacher',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                StreamBuilder<List<TeacherModel>>(
                                  stream: context
                                      .read<StudentManagementProvider>()
                                      .watchTeachers(),
                                  builder: (context, teacherSnapshot) {
                                    final teachers =
                                        teacherSnapshot.data ??
                                        const <TeacherModel>[];
                                    final isTeacherSelected =
                                        selectedTeacherId.isNotEmpty &&
                                        teachers.any(
                                          (t) => t.id == selectedTeacherId,
                                        );

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        border: Border.all(
                                          color: const Color(0xFFE5E7EB),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 0,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline,
                                            size: 20,
                                            color: Color(0xFF2563EB),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              underline:
                                                  const SizedBox.shrink(),
                                              value: isTeacherSelected
                                                  ? selectedTeacherId
                                                  : null,
                                              hint: const Text(
                                                'Select a teacher',
                                              ),
                                              items: teachers
                                                  .map(
                                                    (
                                                      teacher,
                                                    ) => DropdownMenuItem(
                                                      value: teacher.id,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            teacher.fullName,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                          Text(
                                                            teacher.email,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[500],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedTeacherId =
                                                      value ?? '';
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 28),
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: isSaving
                                            ? null
                                            : () => Navigator.of(
                                                bottomSheetContext,
                                              ).pop(),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(
                                            color: Colors.grey[400]!,
                                            width: 1,
                                          ),
                                          foregroundColor: Colors.grey[600],
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton(
                                        onPressed: isSaving
                                            ? null
                                            : () async {
                                                if (formKey.currentState
                                                        ?.validate() !=
                                                    true)
                                                  return;

                                                setDialogState(
                                                  () => isSaving = true,
                                                );

                                                // Store references BEFORE async call
                                                final nav = Navigator.of(
                                                  bottomSheetContext,
                                                );
                                                final messenger =
                                                    ScaffoldMessenger.of(
                                                      bottomSheetContext,
                                                    );
                                                final provider = context
                                                    .read<
                                                      StudentManagementProvider
                                                    >();

                                                try {
                                                  await provider.updateSubject(
                                                    id: subject.id,
                                                    name: nameController.text,
                                                    teacherId:
                                                        selectedTeacherId,
                                                    classIds: selectedClasses
                                                        .toList(),
                                                  );

                                                  // Check if context is still valid after async operation
                                                  if (!bottomSheetContext
                                                      .mounted)
                                                    return;

                                                  // Use stored references
                                                  nav.pop();
                                                  messenger.showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Subject updated successfully.',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  // Check if context is still valid after async operation
                                                  if (!bottomSheetContext
                                                      .mounted)
                                                    return;

                                                  // Use stored references - show error but keep sheet open
                                                  messenger.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to update subject: $e',
                                                      ),
                                                    ),
                                                  );
                                                } finally {
                                                  if (bottomSheetContext
                                                      .mounted) {
                                                    setDialogState(
                                                      () => isSaving = false,
                                                    );
                                                  }
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFF2563EB,
                                          ).withOpacity(0.5),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: isSaving
                                            ? SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Save',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    teacher?.fullName ?? 'Unassigned',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher?.email ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: departmentAppBar(
        context,
        selectedSection == null
            ? 'View Subjects'
            : 'Subjects - $selectedSection',
        customLeading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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

                  // Level 1: Show sections
                  if (selectedSection == null) {
                    final sections = _getAllSections(classes).toList()..sort();
                    if (sections.isEmpty) {
                      return Center(
                        child: Text(
                          'No sections available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Subjects',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${sections.length} section${sections.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(0),
                            itemCount: sections.length,
                            itemBuilder: (context, index) {
                              final section = sections[index];
                              final sectionType = _getSectionType(section);
                              final sectionColor = _getSectionColor(section);
                              final subjectCount = _getSubjectCountForSection(
                                subjects,
                                classes,
                                section,
                              );

                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedSection = section);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: index < sections.length - 1
                                        ? 10
                                        : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border(
                                      left: BorderSide(
                                        color: sectionColor,
                                        width: 4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              section,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$subjectCount subject${subjectCount != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sectionColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              sectionType,
                                              style: TextStyle(
                                                color: sectionColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                            color: sectionColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }

                  // Level 2: Show subjects for selected section
                  final sectionSubjects = _getSubjectsForSection(
                    subjects,
                    classes,
                    selectedSection!,
                  );

                  return ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Section $selectedSection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sectionSubjects.length} subject${sectionSubjects.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sectionSubjects.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No subjects in this section',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(0),
                            itemCount: sectionSubjects.length,
                            itemBuilder: (context, index) {
                              final subject = sectionSubjects[index];
                              final teacher = teacherById[subject.teacherId];
                              final teacherName =
                                  teacher?.fullName ?? 'Unassigned';
                              final assignedClasses = subject.classIds
                                  .map((id) => classById[id])
                                  .whereType<ClassModel>()
                                  .toList();

                              return GestureDetector(
                                onTap: () => _showSubjectDetailSheet(
                                  context,
                                  subject,
                                  teacher,
                                ),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: index < sectionSubjects.length - 1
                                        ? 10
                                        : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border(
                                      left: BorderSide(
                                        color: const Color(0xFF2563EB),
                                        width: 4,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Subject Name + Actions
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () {
                                              _showEditDialog(context, subject);
                                            },
                                            child: Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color: const Color(0xFF2563EB),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              _confirmDelete(context, subject);
                                            },
                                            child: Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Teacher Name
                                      Text(
                                        teacherName,
                                        style: TextStyle(
                                          color: teacher != null
                                              ? const Color(0xFF2563EB)
                                              : Colors.grey[500],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
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
