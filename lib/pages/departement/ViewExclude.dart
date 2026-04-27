import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/exclusion_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';

class ViewExclude extends StatefulWidget {
  const ViewExclude({super.key});

  @override
  State<ViewExclude> createState() => _ViewExcludeState();
}

class _ViewExcludeState extends State<ViewExclude> {
  String? _selectedLevel;
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'View Exclude',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFF8F9FB),
      ),
      body: StreamBuilder<List<ExclusionModel>>(
        stream: provider.watchPendingExclusions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load exclusions: ${snapshot.error}'),
            );
          }

          final items = snapshot.data ?? const <ExclusionModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No pending exclusions.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final byLevel = <String, Map<String, List<ExclusionModel>>>{};
          for (final item in items) {
            final level = item.levelName.trim().isEmpty ? '-' : item.levelName;
            final group = item.groupName.trim().isEmpty ? '-' : item.groupName;
            byLevel.putIfAbsent(level, () => <String, List<ExclusionModel>>{});
            byLevel[level]!.putIfAbsent(group, () => <ExclusionModel>[]);
            byLevel[level]![group]!.add(item);
          }

          final levels = byLevel.keys.toList()..sort();

          if (_selectedLevel == null || !byLevel.containsKey(_selectedLevel)) {
            return _buildLevelList(levels, byLevel);
          }

          final groupsMap = byLevel[_selectedLevel!]!;
          final groups = groupsMap.keys.toList()..sort();

          if (_selectedGroup == null ||
              !groupsMap.containsKey(_selectedGroup)) {
            return _buildGroupList(_selectedLevel!, groups, groupsMap);
          }

          return _buildStudentList(
            level: _selectedLevel!,
            group: _selectedGroup!,
            items: groupsMap[_selectedGroup!]!,
          );
        },
      ),
    );
  }

  Widget _buildLevelList(
    List<String> levels,
    Map<String, Map<String, List<ExclusionModel>>> byLevel,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        final total = byLevel[level]!.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        );

        return _AnimatedCard(
          child: ListTile(
            leading: const Icon(
              Icons.layers_outlined,
              color: Color(0xFF2563EB),
            ),
            title: Text(
              level,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('$total pending exclusion(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() {
              _selectedLevel = level;
              _selectedGroup = null;
            }),
          ),
        );
      },
    );
  }

  Widget _buildGroupList(
    String level,
    List<String> groups,
    Map<String, List<ExclusionModel>> groupsMap,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selectedLevel = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Levels'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final total = groupsMap[group]!.length;

              return _AnimatedCard(
                child: ListTile(
                  leading: const Icon(
                    Icons.group_outlined,
                    color: Color(0xFF7C3AED),
                  ),
                  title: Text(
                    '$level • $group',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('$total pending exclusion(s)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selectedGroup = group),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList({
    required String level,
    required String group,
    required List<ExclusionModel> items,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _selectedGroup = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Groups'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _AnimatedCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Color(0xFF101828),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Color(0xFFB54708),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Subject: ${item.subjectName}'),
                      Text('Teacher: ${item.teacherName}'),
                      Text('Total absences: ${item.totalAbsences}'),
                      Text(
                        'Justified: ${item.justifiedAbsences} • Unjustified: ${item.unjustifiedAbsences}',
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _updateStatus(item, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF12B76A),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve Exclusion'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _updateStatus(item, 'rejected'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB42318),
                                side: const BorderSide(
                                  color: Color(0xFFB42318),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject Exclusion'),
                            ),
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
      ],
    );
  }

  Future<void> _updateStatus(ExclusionModel item, String status) async {
    try {
      await context.read<StudentManagementProvider>().updateExclusionStatus(
        id: item.id,
        status: status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exclusion ${status.toUpperCase()} for ${item.studentName}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update exclusion: $e')));
    }
  }
}

class _AnimatedCard extends StatelessWidget {
  const _AnimatedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
