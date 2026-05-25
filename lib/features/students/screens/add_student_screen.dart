import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/core/constants/group_model.dart';
import 'package:test/core/constants/level_model.dart';
import 'package:test/features/students/providers/student_management_provider.dart';
import 'package:test/features/departments/widgets/common_widgets.dart';
import 'package:test/core/theme/app_theme.dart';

// ========================================
// Add Student Screen
// Collects student details and creates the
// linked auth and Firestore records.
// ========================================

class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  

  String? _selectedLevelId;
  String? _selectedGroupId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    // Attendance percentage removed from UI; default to 0 on creation
    final attendanceValue = 0;

    setState(() => _isSubmitting = true);

    try {
      await context.read<StudentManagementProvider>().addStudent(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        attendancePercentage: attendanceValue,
        groupId: _selectedGroupId!,
        levelId: _selectedLevelId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Student added successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      print('❌ Error adding student: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to add student: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
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
      // FIXED: Replaced hardcoded background with theme color
      backgroundColor: AppTheme.lightBackground,
      appBar: departmentAppBar(
        context,
        "Add Student",
        customLeading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                      // FIXED: Replaced hardcoded gradient with theme colors
                      gradient: const LinearGradient(
                        colors: [AppTheme.lightPrimary, AppTheme.lightPrimaryDark],
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
                          enabled: !_isSubmitting,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the student name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isSubmitting,
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
                              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isSubmitting,
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
                          enabled: !_isSubmitting,
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
                        const SizedBox(height: 16),
                        // Attendance percentage removed — default handled on submit
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

                            if (!hasSelectedLevel && _selectedLevelId != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _selectedLevelId = null;
                                    _selectedGroupId = null;
                                  });
                                }
                              });
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedLevelId,
                              isExpanded: true,
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
                              onChanged: _isSubmitting
                                  ? null
                                  : (value) {
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
                                .watchGroupsByLevel(levelId: _selectedLevelId!),
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

                              if (!hasSelectedGroup &&
                                  _selectedGroupId != null) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedGroupId = null;
                                    });
                                  }
                                });
                              }

                              return DropdownButtonFormField<String>(
                                initialValue: _selectedGroupId,
                                isExpanded: true,
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
                                onChanged: _isSubmitting
                                    ? null
                                    : (value) {
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
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Select level first to load groups.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              // FIXED: Replaced hardcoded button color with theme color
                              backgroundColor: AppTheme.lightPrimary,
                              disabledBackgroundColor: Colors.grey.shade400,
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
                                      color: Colors.white,
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
