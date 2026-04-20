import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/level_model.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/students_screen.dart';
import 'package:test/pages/departement/widgets/hierarchy_item_card.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  static const String routeName = '/students/groups';

  Future<void> _showAddGroupDialog(
    BuildContext context,
    LevelModel level,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    var isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text('Add group in ${level.name}'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'Group 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Group name is required';
                    }
                    return null;
                  },
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
                          if (formKey.currentState?.validate() != true) {
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            await context
                                .read<StudentManagementProvider>()
                                .addGroup(
                                  name: nameController.text,
                                  levelId: level.id,
                                );

                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Group added successfully.',
                                      ),
                                    ),
                                  );
                                }
                              });
                            }
                          } catch (_) {
                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to add group. Please check network and try again.',
                                      ),
                                    ),
                                  );
                                }
                              });
                            }
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
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! LevelModel) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: departmentAppBar(context, 'Groups'),
        drawer: departmentDrawer(context),
        body: Center(
          child: Text(
            'Unable to open groups: invalid level data.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final level = args;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: departmentAppBar(context, 'Groups - ${level.name}'),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a group in ${level.name}',
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder(
                stream: context
                    .read<StudentManagementProvider>()
                    .watchGroupsByLevel(levelId: level.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load groups. Please verify your network.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    );
                  }

                  final groups = snapshot.data ?? const [];
                  if (groups.isEmpty) {
                    return Center(
                      child: Text(
                        'No groups found for ${level.name}. Add one using + button.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return HierarchyItemCard(
                        title: group.name,
                        subtitle: 'Tap to view students',
                        leadingIcon: Icons.groups_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          StudentsScreen.routeName,
                          arguments: StudentsScreenArgs(
                            level: level,
                            group: group,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupDialog(context, level),
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}
