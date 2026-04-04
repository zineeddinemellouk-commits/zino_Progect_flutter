import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/class_model.dart';
import 'package:test/models/subject_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'common_widgets.dart';

class AddTeacher extends StatefulWidget {
  const AddTeacher({super.key});

  @override
  State<AddTeacher> createState() => _AddTeacherState();
}

class _AddTeacherState extends State<AddTeacher> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final List<String> _selectedSubjects = [];
  final List<String> _selectedClasses = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() != true) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject')),
      );
      return;
    }
    if (_selectedClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one class')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<StudentManagementProvider>().addTeacher(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        subjectIds: _selectedSubjects,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add teacher: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, "Add Teacher"),
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
                          "Add New Teacher",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Enter teacher information below",
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
                          "Teacher Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the teacher name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
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
                        const SizedBox(height: 20),
                        const Text(
                          "Subjects",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<SubjectModel>>(
                          stream: context
                              .watch<StudentManagementProvider>()
                              .watchSubjects(),
                          builder: (context, snapshot) {
                            final subjects =
                                snapshot.data ?? const <SubjectModel>[];
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (subjects.isEmpty) {
                              return const Text(
                                'No subjects found. Add subjects first.',
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              children: subjects.map((subject) {
                                final isSelected = _selectedSubjects.contains(
                                  subject.id,
                                );
                                return FilterChip(
                                  label: Text(subject.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSubjects.add(subject.id);
                                      } else {
                                        _selectedSubjects.remove(subject.id);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF2563EB),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Classes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<ClassModel>>(
                          stream: context
                              .watch<StudentManagementProvider>()
                              .watchClasses(),
                          builder: (context, snapshot) {
                            final classes =
                                snapshot.data ?? const <ClassModel>[];
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            if (classes.isEmpty) {
                              return const Text('No classes found.');
                            }
                            return Wrap(
                              spacing: 8,
                              children: classes.map((classLevel) {
                                final isSelected = _selectedClasses.contains(
                                  classLevel.id,
                                );
                                return FilterChip(
                                  label: Text(classLevel.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedClasses.add(classLevel.id);
                                      } else {
                                        _selectedClasses.remove(classLevel.id);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(
                                    0xFF2563EB,
                                  ).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFF2563EB),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Teacher',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}
