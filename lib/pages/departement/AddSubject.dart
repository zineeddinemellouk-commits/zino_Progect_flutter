// create the AddSubject page with a form to add a new subject to the department
import 'package:flutter/material.dart';
import 'common_widgets.dart';

class AddSubject extends StatefulWidget {
  const AddSubject({super.key});

  @override
  _AddSubjectState createState() => _AddSubjectState();
}

class _AddSubjectState extends State<AddSubject> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();

  final List<String> _allTeachers = [
    'Dr. Smith',
    'Prof. Ahmed',
    'Dr. Johnson',
    'Prof. Carter',
  ];

  final List<String> _selectedTeachers = [];

  final Map<String, bool> _levels = {
    'Licence 1': false,
    'Licence 2': false,
    'Licence 3': false,
    'Master 1': false,
    'Master 2': false,
  };

  @override
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final subjectName = _subjectNameController.text.trim();
    final selectedLevels = _levels.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (_selectedTeachers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one teacher.')),
      );
      return;
    }

    if (selectedLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one level.')),
      );
      return;
    }

    // TODO: connect this data to database or backend.
    final createdSubject = {
      'subjectName': subjectName,
      'teachers': _selectedTeachers,
      'levels': selectedLevels,
    };

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Subject created: $createdSubject')));

    _formKey.currentState?.reset();
    _subjectNameController.clear();
    setState(() {
      _selectedTeachers.clear();
      _levels.updateAll((key, value) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, "Add Subject"),
      drawer: departmentDrawer(context),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            right: -20,
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/PixVerse_Image_Effect_prompt_invsibel backgrou.jpg',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),
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
                          'Assign Teachers',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allTeachers.map((teacher) {
                            final selected = _selectedTeachers.contains(
                              teacher,
                            );
                            return FilterChip(
                              label: Text(teacher),
                              selected: selected,
                              onSelected: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedTeachers.add(teacher);
                                  } else {
                                    _selectedTeachers.remove(teacher);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Levels',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._levels.keys.map((level) {
                          return CheckboxListTile(
                            title: Text(level),
                            value: _levels[level],
                            onChanged: (value) {
                              setState(() {
                                _levels[level] = value ?? false;
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Create Subject'),
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
