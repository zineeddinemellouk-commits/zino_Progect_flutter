import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/groups_screen.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/widgets/hierarchy_item_card.dart';

/// First hierarchy level screen: Levels (L1, L2, L3, M1, M2).
class ViewStudent extends StatelessWidget {
  const ViewStudent({super.key});

  static const String routeName = '/students/levels';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, 'Student Management - Levels'),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a level to explore groups and students',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder(
                stream: context.read<StudentManagementProvider>().watchLevels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load levels. Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  }

                  final levels = snapshot.data ?? const [];
                  if (levels.isEmpty) {
                    return Center(
                      child: Text(
                        'No levels found yet.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];

                      return HierarchyItemCard(
                        title: level.name,
                        subtitle: 'Tap to view available groups',
                        leadingIcon: Icons.school_rounded,
                        onTap: () => Navigator.pushNamed(
                          context,
                          GroupsScreen.routeName,
                          arguments: level,
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
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }
}
