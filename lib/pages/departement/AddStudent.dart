import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/group_model.dart';
import 'package:test/models/level_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'common_widgets.dart';

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _attendanceController = TextEditingController(text: '0');

  String? _selectedLevelId;
  String? _selectedGroupId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _attendanceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    final attendanceValue = int.tryParse(_attendanceController.text.trim());
    if (attendanceValue == null ||
        attendanceValue < 0 ||
        attendanceValue > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance must be between 0 and 100.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await context.read<StudentManagementProvider>().addStudent(
        fullName: _nameController.text,
        email: _emailController.text,
        attendancePercentage: attendanceValue,
        groupId: _selectedGroupId!,
        levelId: _selectedLevelId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to add student. Please check network and retry.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, "Add Student"),
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
                          "Add New Student",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Enter student information below",
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
                          "Student Details",
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
                              return 'Please enter the student name';
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _attendanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Attendance %',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.percent),
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null) {
                              return 'Please enter a number';
                            }
                            if (parsed < 0 || parsed > 100) {
                              return 'Value must be from 0 to 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<LevelModel>>(
                          stream: context
                              .read<StudentManagementProvider>()
                              .watchLevels(),
                          builder: (context, levelSnapshot) {
                            if (levelSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (levelSnapshot.hasError) {
                              return Text(
                                'Unable to load levels. Check your connection.',
                                style: TextStyle(color: Colors.red.shade700),
                              );
                            }

                            final levels = levelSnapshot.data ?? const [];

                            if (levels.isEmpty) {
                              return Text(
                                'No levels available. Please create levels first.',
                                style: TextStyle(color: Colors.grey.shade700),
                              );
                            }

                            final hasSelectedLevel = levels.any(
                              (level) => level.id == _selectedLevelId,
                            );
                            if (!hasSelectedLevel) {
                              _selectedLevelId = null;
                              _selectedGroupId = null;
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedLevelId,
                              decoration: const InputDecoration(
                                labelText: 'Level of Study',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.school),
                              ),
                              items: levels.map((level) {
                                return DropdownMenuItem(
                                  value: level.id,
                                  child: Text(level.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLevelId = value;
                                  _selectedGroupId = null;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a level of study';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_selectedLevelId != null)
                          StreamBuilder<List<GroupModel>>(
                            stream: context
                                .read<StudentManagementProvider>()
                                .watchGroupsByLevel(_selectedLevelId!),
                            builder: (context, groupSnapshot) {
                              if (groupSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (groupSnapshot.hasError) {
                                return Text(
                                  'Unable to load groups for selected level.',
                                  style: TextStyle(color: Colors.red.shade700),
                                );
                              }

                              final groups = groupSnapshot.data ?? const [];
                              if (groups.isEmpty) {
                                return Text(
                                  'No groups found for selected level.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                );
                              }

                              final hasSelectedGroup = groups.any(
                                (group) => group.id == _selectedGroupId,
                              );
                              if (!hasSelectedGroup) {
                                _selectedGroupId = null;
                              }

                              return DropdownButtonFormField<String>(
                                initialValue: _selectedGroupId,
                                decoration: const InputDecoration(
                                  labelText: 'Group',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.group),
                                ),
                                items: groups.map((group) {
                                  return DropdownMenuItem(
                                    value: group.id,
                                    child: Text(group.name),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGroupId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a group';
                                  }
                                  return null;
                                },
                              );
                            },
                          )
                        else
                          Text(
                            'Select level first to load groups.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Add Student',
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
      bottomNavigationBar: departmentBottomNav(context, 0),
    );
  }
}
