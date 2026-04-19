import 'package:flutter/material.dart';
import 'package:test/features/teachers/data/teachers_firestore_service.dart';

class TeacherAttendanceHistoryPage extends StatefulWidget {
  const TeacherAttendanceHistoryPage({
    super.key,
    required this.teacherId,
    required this.teacherEmail,
  });

  final String teacherId;
  final String teacherEmail;

  @override
  State<TeacherAttendanceHistoryPage> createState() =>
      _TeacherAttendanceHistoryPageState();
}

class _TeacherAttendanceHistoryPageState
    extends State<TeacherAttendanceHistoryPage> {
  final TeachersFirestoreService _service = TeachersFirestoreService();
  final Map<String, bool> _expandedLevels = {};
  final Map<String, bool> _expandedGroups = {};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFDDE5F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
                decoration: const InputDecoration(
                  hintText: 'Search by level, group, or date...',
                  hintStyle:
                      TextStyle(color: Color(0xFF667085), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Color(0xFF667085)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          // History list organized by levels and groups
          Expanded(
            child: StreamBuilder<List<TeacherAttendanceHistoryItem>>(
              stream: _service.watchTeacherAttendanceHistory(
                widget.teacherId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Error loading history: ${snapshot.error}'),
                    ),
                  );
                }

                final allHistory =
                    snapshot.data ?? const <TeacherAttendanceHistoryItem>[];

                if (allHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No attendance history yet',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Organize history by Level → Group
                final levelMap =
                    <String, Map<String, List<TeacherAttendanceHistoryItem>>>{};

                for (final item in allHistory) {
                  final levelKey = '${item.levelId}|${item.levelName}';
                  final groupKey = '${item.groupId}|${item.groupName}';

                  levelMap.putIfAbsent(levelKey, () => {});
                  levelMap[levelKey]!.putIfAbsent(groupKey, () => []);
                  levelMap[levelKey]![groupKey]!.add(item);
                }

                // Sort items within each group by date (newest first)
                levelMap.forEach((level, groups) {
                  groups.forEach((group, items) {
                    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  });
                });

                // Sort levels
                final sortedLevels = levelMap.keys.toList()
                  ..sort((a, b) =>
                      a.split('|')[1].compareTo(b.split('|')[1]));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: sortedLevels.length,
                  itemBuilder: (context, levelIndex) {
                    final levelKey = sortedLevels[levelIndex];
                    final levelParts = levelKey.split('|');
                    final levelId = levelParts[0];
                    final levelName = levelParts[1];
                    final groups = levelMap[levelKey]!;

                    // Filter by search query
                    final filteredGroups =
                        <String, List<TeacherAttendanceHistoryItem>>{};
                    groups.forEach((groupKey, items) {
                      final groupParts = groupKey.split('|');
                      final groupName = groupParts[1];

                      final filtered = items.where((item) {
                        if (_searchQuery.isEmpty) return true;
                        return levelName
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            groupName.toLowerCase().contains(_searchQuery) ||
                            _formatDate(item.createdAt)
                                .toLowerCase()
                                .contains(_searchQuery);
                      }).toList();

                      if (filtered.isNotEmpty) {
                        filteredGroups[groupKey] = filtered;
                      }
                    });

                    if (filteredGroups.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final isLevelExpanded =
                        _expandedLevels.putIfAbsent(levelId, () => true);

                    return Column(
                      children: [
                        // Level header (expandable)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAEFFB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _expandedLevels[levelId] =
                                      !isLevelExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLevelExpanded
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: const Color(0xFF4A40CF),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      levelName,
                                      style: const TextStyle(
                                        color: Color(0xFF101828),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A40CF),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${filteredGroups.length} group${filteredGroups.length != 1 ? 's' : ''}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Groups under this level
                        if (isLevelExpanded)
                          ...filteredGroups.entries.map((groupEntry) {
                            final groupKey = groupEntry.key;
                            final groupParts = groupKey.split('|');
                            final groupName = groupParts[1];
                            final items = groupEntry.value;

                            final isGroupExpanded = _expandedGroups
                                .putIfAbsent(groupKey, () => true);

                            return Column(
                              children: [
                                // Group header (expandable)
                                Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 0,
                                    left: 12,
                                    top: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE4E7EC),
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        setState(() {
                                          _expandedGroups[groupKey] =
                                              !isGroupExpanded;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isGroupExpanded
                                                  ? Icons.expand_less_rounded
                                                  : Icons.expand_more_rounded,
                                              color:
                                                  const Color(0xFF667085),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              groupName,
                                              style: const TextStyle(
                                                color: Color(0xFF101828),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0F9FF),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFF0EA5E9),
                                                ),
                                              ),
                                              child: Text(
                                                '${items.length}',
                                                style: const TextStyle(
                                                  color: Color(0xFF0369A1),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // History items under this group
                                if (isGroupExpanded)
                                  Container(
                                    margin: const EdgeInsets.only(
                                      left: 12,
                                      bottom: 12,
                                    ),
                                    child: Column(
                                      children: items.map((item) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color:
                                                  const Color(0xFFE4E7EC),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _formatDate(
                                                              item.createdAt),
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF101828),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          _formatTime(
                                                              item.createdAt),
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF667085),
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.totalStudents} students',
                                                    style: const TextStyle(
                                                      color:
                                                          Color(0xFF667085),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  _statusChip(
                                                    label:
                                                        'Present ${item.presentCount}',
                                                    color: const Color(
                                                        0xFF067647),
                                                    bg: const Color(
                                                        0xFFE7F8EF),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _statusChip(
                                                    label:
                                                        'Absent ${item.absentCount}',
                                                    color: const Color(
                                                        0xFFB42318),
                                                    bg: const Color(
                                                        0xFFFEE4E2),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
