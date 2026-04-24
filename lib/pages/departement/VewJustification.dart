import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/justification_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class VewJustification extends StatefulWidget {
  const VewJustification({super.key});

  @override
  State<VewJustification> createState() => _VewJustificationState();
}

class _VewJustificationState extends State<VewJustification> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'rejected'
  int _currentLevel = 1; // 1: sections, 2: groups, 3: justifications
  String? _selectedSection;
  String? _selectedGroup;

  String _normalizeStatus(String status) {
    final normalized = status.toLowerCase().trim();
    return normalized == 'refused' ? 'rejected' : normalized;
  }

  bool _matchesFilter(String status) {
    final normalized = _normalizeStatus(status);
    switch (_selectedFilter) {
      case 'pending':
        return normalized == 'submitted';
      case 'accepted':
        return normalized == 'accepted';
      case 'rejected':
        return normalized == 'rejected';
      default:
        return true;
    }
  }

  Map<String, Map<String, List<JustificationModel>>> _groupJustifications(
    List<JustificationModel> items,
  ) {
    final grouped = <String, Map<String, List<JustificationModel>>>{};

    for (final item in items) {
      if (!_matchesFilter(item.status)) continue;

      final section = item.levelName ?? 'Unknown';
      final group = item.groupName ?? 'Unknown';

      grouped.putIfAbsent(section, () => {});
      grouped[section]!.putIfAbsent(group, () => []);
      grouped[section]![group]!.add(item);
    }

    return grouped;
  }

  Map<String, int> _getSectionStats(
    List<JustificationModel> allItems,
    String section,
  ) {
    final sectionItems = allItems.where((j) => j.levelName == section).toList();
    final pending = sectionItems.where((j) => j.status == 'submitted').length;
    final total = sectionItems.length;
    return {'pending': pending, 'total': total};
  }

  Map<String, int> _getGroupStats(
    List<JustificationModel> allItems,
    String section,
    String group,
  ) {
    final groupItems = allItems
        .where((j) => j.levelName == section && j.groupName == group)
        .toList();
    final pending = groupItems.where((j) => j.status == 'submitted').length;
    final total = groupItems.length;
    return {'pending': pending, 'total': total};
  }

  bool _isLicenceLevel(String section) {
    return section.startsWith('L');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentManagementProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        leading: _currentLevel > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_currentLevel == 3) {
                      _currentLevel = 2;
                      _selectedGroup = null;
                    } else if (_currentLevel == 2) {
                      _currentLevel = 1;
                      _selectedSection = null;
                    }
                  });
                },
              )
            : null,
        title: Text(
          _currentLevel == 1
              ? context.tr('justification_requests')
              : _currentLevel == 2
              ? _selectedSection ?? ''
              : '$_selectedSection › $_selectedGroup',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<JustificationModel>>(
          stream: provider.watchJustifications(),
          builder: (context, snapshot) {
            final allItems = snapshot.data ?? const <JustificationModel>[];
            final pending = allItems
                .where((j) => j.status == 'submitted')
                .length;
            final total = allItems.length;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('${context.tr('error')}: ${snapshot.error}'),
              );
            }

            if (allItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No justification requests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show appropriate level view
            if (_currentLevel == 1) {
              return _buildSectionsView(context, allItems, pending, total);
            } else if (_currentLevel == 2) {
              return _buildGroupsView(context, allItems, _selectedSection!);
            } else {
              return _buildJustificationsView(
                context,
                allItems,
                _selectedSection!,
                _selectedGroup!,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionsView(
    BuildContext context,
    List<JustificationModel> allItems,
    int pending,
    int total,
  ) {
    // Get unique sections
    final sections = <String>{};
    for (final item in allItems) {
      sections.add(item.levelName ?? 'Unknown');
    }
    final sortedSections = sections.toList()
      ..sort((a, b) {
        final aIsLicence = _isLicenceLevel(a);
        final bIsLicence = _isLicenceLevel(b);
        if (aIsLicence != bIsLicence) {
          return aIsLicence ? -1 : 1;
        }
        return a.compareTo(b);
      });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
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
                Icon(Icons.assignment_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Justification Requests',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$pending pending · $total total',
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
                    '$total Requests',
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedSections.length,
            itemBuilder: (context, index) {
              final section = sortedSections[index];
              final stats = _getSectionStats(allItems, section);
              final sectionPending = stats['pending'] ?? 0;
              final sectionTotal = stats['total'] ?? 0;
              final isLicence = _isLicenceLevel(section);
              final accentColor = isLicence
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF7C3AED);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentLevel = 2;
                      _selectedSection = section;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: accentColor, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isLicence ? 'Licence' : 'Master',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (sectionPending > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$sectionPending pending',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '$sectionTotal total',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsView(
    BuildContext context,
    List<JustificationModel> allItems,
    String section,
  ) {
    // Get groups for this section
    final groups = <String>{};
    for (final item in allItems.where((j) => j.levelName == section)) {
      groups.add(item.groupName ?? 'Unknown');
    }
    final sortedGroups = groups.toList()..sort();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final group = sortedGroups[index];
              final stats = _getGroupStats(allItems, section, group);
              final groupPending = stats['pending'] ?? 0;
              final groupTotal = stats['total'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentLevel = 3;
                      _selectedGroup = group;
                      _selectedFilter = 'all'; // Reset filter
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(
                          color: const Color(0xFF2563EB),
                          width: 4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                section,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (groupPending > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$groupPending pending',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '$groupTotal total',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJustificationsView(
    BuildContext context,
    List<JustificationModel> allItems,
    String section,
    String group,
  ) {
    final justifications = allItems
        .where((j) => j.levelName == section && j.groupName == group)
        .where((item) => _matchesFilter(item.status))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('accepted', 'Accepted'),
                const SizedBox(width: 8),
                _buildFilterChip('rejected', 'Rejected'),
              ],
            ),
          ),
        ),
        Expanded(
          child: justifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: justifications.length,
                  itemBuilder: (context, index) {
                    final item = justifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _JustificationCard(
                        item: item,
                        onTap: () => _showDetails(context, item),
                        onAccept: () => _handleAccept(context, item),
                        onReject: () => _showRejectDialog(context, item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2563EB),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      side: isSelected
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 1),
    );
  }

  Future<void> _handleAccept(
    BuildContext context,
    JustificationModel item,
  ) async {
    await context.read<StudentManagementProvider>().updateJustificationStatus(
      id: item.id,
      status: 'accepted',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('accept_justification'))),
      );
    }
  }

  void _showRejectDialog(BuildContext context, JustificationModel item) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Justification'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('refusal_reason'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = controller.text.trim();
              await context
                  .read<StudentManagementProvider>()
                  .updateJustificationStatus(
                    id: item.id,
                    status: 'refused',
                    refusalReason: reason,
                  );
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('refuse_justification'))),
                );
              }
            },
            child: Text(context.tr('refuse')),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, JustificationModel item) {
    showDialog<void>(
      context: context,
      builder: (_) => _JustificationDetailsDialog(
        item: item,
        onApprove: () async {
          await context
              .read<StudentManagementProvider>()
              .updateJustificationStatus(id: item.id, status: 'accepted');
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('accept_justification'))),
            );
          }
        },
        onReject: (reason) async {
          await context
              .read<StudentManagementProvider>()
              .updateJustificationStatus(
                id: item.id,
                status: 'refused',
                refusalReason: reason,
              );
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('refuse_justification'))),
            );
          }
        },
      ),
    );
  }
}

class _JustificationCard extends StatelessWidget {
  const _JustificationCard({
    required this.item,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  final JustificationModel item;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final initials = (item.studentName ?? 'Student')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();

    final status = item.status.toLowerCase() == 'refused'
        ? 'rejected'
        : item.status.toLowerCase();
    final statusColor = switch (status) {
      'accepted' => const Color(0xFF16A34A),
      'rejected' => const Color(0xFFDC2626),
      'submitted' => const Color(0xFFF59E0B),
      _ => const Color(0xFFF59E0B),
    };
    final statusLabel = switch (status) {
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      'submitted' => 'Submitted',
      _ => 'Pending',
    };
    final isSubmitted = status == 'submitted';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.studentName ?? 'Unknown Student',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.subject} • ${item.teacherName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Absence: ${item.absenceDate.toIso8601String().split('T').first}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.send,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Submitted: ${item.createdAt.toIso8601String().split('T').first}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${item.reason ?? '-'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isSubmitted) ...[
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey.withOpacity(0.1)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onAccept,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Accept',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onReject,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFDC2626),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Reject',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JustificationDetailsDialog extends StatefulWidget {
  const _JustificationDetailsDialog({
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  final JustificationModel item;
  final VoidCallback onApprove;
  final Future<void> Function(String reason) onReject;

  @override
  State<_JustificationDetailsDialog> createState() =>
      _JustificationDetailsDialogState();
}

class _JustificationDetailsDialogState
    extends State<_JustificationDetailsDialog> {
  final TextEditingController _refusalReasonController =
      TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _refusalReasonController.dispose();
    super.dispose();
  }

  Future<void> _openFile() async {
    final url = widget.item.fileUrl.trim();
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.studentName ?? 'Unknown Student'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${context.tr('level')}: ${widget.item.levelName ?? 'Unknown Level'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${context.tr('group')}: ${widget.item.groupName ?? 'Unknown Group'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('${widget.item.subject} • ${widget.item.teacherName}'),
              const SizedBox(height: 8),
              Text(
                '${context.tr('absence_date')}: ${widget.item.absenceDate.toIso8601String().split('T').first}',
              ),
              const SizedBox(height: 8),
              Text(
                '${context.tr('submitted_date')}: ${widget.item.createdAt.toIso8601String().split('T').first}',
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('reason'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(widget.item.reason ?? 'No reason provided.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    context.tr('attachment'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openFile,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(context.tr('view_file')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _refusalReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.tr('refusal_reason'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('close')),
        ),
        if (widget.item.status.toLowerCase() == 'submitted') ...[
          TextButton(
            onPressed: _isRejecting
                ? null
                : () async {
                    final reason = _refusalReasonController.text.trim();
                    setState(() => _isRejecting = true);
                    try {
                      await widget.onReject(reason);
                    } finally {
                      if (mounted) setState(() => _isRejecting = false);
                    }
                  },
            child: Text(context.tr('refuse')),
          ),
          ElevatedButton(
            onPressed: _isRejecting ? null : widget.onApprove,
            child: Text(context.tr('accept')),
          ),
        ],
      ],
    );
  }
}
