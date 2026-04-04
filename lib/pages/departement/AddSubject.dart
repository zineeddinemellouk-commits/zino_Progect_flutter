// create the AddSubject page with a form to add a new subject to the department
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/teacher_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'common_widgets.dart';

class AddSubject extends StatefulWidget {
  const AddSubject({super.key});

  @override
  _AddSubjectState createState() => _AddSubjectState();
}

class _AddSubjectState extends State<AddSubject> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();
  final List<String> _selectedTeachers = [];
  final Map<String, bool> _selectedClasses = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final subjectName = _subjectNameController.text.trim();
    final selectedClassIds = _selectedClasses.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (_selectedTeachers.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select only one teacher.')),
      );
      return;
    }

    if (selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<StudentManagementProvider>().addSubject(
        name: subjectName,
        teacherId: _selectedTeachers.isNotEmpty ? _selectedTeachers.first : '',
        classIds: selectedClassIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject created successfully!')),
      );
      _formKey.currentState?.reset();
      _subjectNameController.clear();
      setState(() {
        _selectedTeachers.clear();
        _selectedClasses.updateAll((key, value) => false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create subject: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, "Add Subject"),
      drawer: departmentDrawer(context),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add New Subject",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Enter subject information below",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Subject Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _subjectNameController,
                          decoration: const InputDecoration(
                            labelText: 'Subject Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Subject name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Assign Teacher (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<List<TeacherModel>>(
                          stream: context
                              .watch<StudentManagementProvider>()
                              .watchTeachers(),
                          builder: (context, snapshot) {
                            final teachers = snapshot.data ?? const <TeacherModel>[];
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (teachers.isEmpty) {
                              return const Text(
                                'No teachers found. You can still create the subject.',
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: teachers.map((teacher) {
                                final selected = _selectedTeachers.contains(teacher.id);
                                return FilterChip(
                                  label: Text(teacher.fullName),
                                  selected: selected,
                                  onSelected: (isSelected) {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTeachers.add(teacher.id);
                                      } else {
                                        _selectedTeachers.remove(teacher.id);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Levels', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        StreamBuilder<List<ClassModel>>(
                          stream: context
                              .watch<StudentManagementProvider>()
                              .watchClasses(),
                          builder: (context, snapshot) {
                            final classes = snapshot.data ?? const <ClassModel>[];
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (classes.isEmpty) {
                              return const Text('No classes found.');
                            }
                            for (final c in classes) {
                              _selectedClasses.putIfAbsent(c.id, () => false);
                            }
                            return Column(
                              children: classes
                                  .map(
                                    (c) => CheckboxListTile(
                                      title: Text(c.name),
                                      value: _selectedClasses[c.id] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedClasses[c.id] = value ?? false;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Create Subject'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: departmentBottomNav(context, 2),
    );
  }
}
