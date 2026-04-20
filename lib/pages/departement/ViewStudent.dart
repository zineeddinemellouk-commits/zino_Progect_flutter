import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/groups_screen.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/pages/departement/widgets/hierarchy_item_card.dart';
import 'package:test/helpers/localization_helper.dart';

/// First hierarchy level screen: Levels (L1, L2, L3, M1, M2).
class ViewStudent extends StatelessWidget {
  const ViewStudent({super.key});

  static const String routeName = '/students/levels';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: departmentAppBar(context, context.tr('students')),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: context.isRtl
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('filter'),
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
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
                        context.tr('error'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }

                  final levels = snapshot.data ?? const [];
                  if (levels.isEmpty) {
                    return Center(
                      child: Text(
                        context.tr('loading'),
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];

                      return HierarchyItemCard(
                        title: level.name,
                        subtitle: 'Tap to view groups',
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
