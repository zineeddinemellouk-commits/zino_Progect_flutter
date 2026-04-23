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

  bool _isLicenceLevel(String levelName) {
    return levelName.startsWith('L');
  }

  String _getLevelType(String levelName) {
    return _isLicenceLevel(levelName) ? 'Licence' : 'Master';
  }

  Color _getLevelColor(String levelName) {
    return _isLicenceLevel(levelName)
        ? const Color(0xFF2563EB)
        : const Color(0xFF7C3AED);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, context.tr('students')),
      drawer: departmentDrawer(context),
      body: StreamBuilder(
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
                style: TextStyle(color: Colors.grey.shade700),
              ),
            );
          }

          final levels = snapshot.data ?? const [];
          if (levels.isEmpty) {
            return Center(
              child: Text(
                context.tr('loading'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select a Section',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a section to view students',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${levels.length} Sections',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Licence Sections
              ..._buildSectionGroup(context, levels, true),
              // Master Sections
              ..._buildSectionGroup(context, levels, false),
            ],
          );
        },
      ),
      bottomNavigationBar: departmentBottomNav(context, 1),
    );
  }

  List<Widget> _buildSectionGroup(
    BuildContext context,
    List<dynamic> levels,
    bool isLicence,
  ) {
    final filtered = levels
        .where((level) => _isLicenceLevel(level.name) == isLicence)
        .toList();

    if (filtered.isEmpty) return [];

    final header = isLicence ? '🎓 Licence' : '🎓 Master';
    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Text(
          header,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    ];

    for (final level in filtered) {
      final color = _getLevelColor(level.name);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(
                context,
                GroupsScreen.routeName,
                arguments: level,
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(left: BorderSide(color: color, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.class_outlined, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getLevelType(level.name),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}
