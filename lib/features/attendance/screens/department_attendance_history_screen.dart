import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/core/theme/app_theme.dart';

class DepartmentAttendanceHistoryScreen extends StatefulWidget {
  const DepartmentAttendanceHistoryScreen({super.key});

  @override
  State<DepartmentAttendanceHistoryScreen> createState() =>
      _DepartmentAttendanceHistoryScreenState();
}

class _DepartmentAttendanceHistoryScreenState
    extends State<DepartmentAttendanceHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedTeacher = 'All';
  List<String> _teachers = ['All'];
  Map<String, String> _teacherIdToName = {}; // Cache for teacher names

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    try {
      final snapshot = await _firestore.collection('teachers').get();
      final teacherNames = <String>[];
      final idToName = <String, String>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          teacherNames.add(fullName);
          idToName[doc.id] = fullName;
        }
      }

      teacherNames.sort();

      if (!mounted) return;
      setState(() {
        _teachers = ['All', ...teacherNames];
        _teacherIdToName = idToName;
      });
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: AppTheme.lightOnSurface,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim().toLowerCase());
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search by teacher, group, or date...',
                      hintStyle: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Color(0xFF667085)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Teacher Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _teachers
                        .map((teacher) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(teacher),
                                selected: _selectedTeacher == teacher,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTeacher =
                                        selected ? teacher : 'All';
                                  });
                                },
                                backgroundColor: AppTheme.lightBorder
                                    .withOpacity(0.2),
                                selectedColor: AppTheme.lightPrimary
                                    .withOpacity(0.2),
                                side: BorderSide(
                                  color: _selectedTeacher == teacher
                                      ? AppTheme.lightPrimary
                                      : AppTheme.lightBorder,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          // History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('attendance_history')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
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

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
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
                        Text(
                          'No attendance history found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group attendance by teacher and group
                final grouped = _groupAttendanceData(docs);

                if (grouped.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching records found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final entry = grouped.entries.elementAt(index);
                    final teacherName = entry.key;
                    final groupsData = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Teacher Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                          child: Text(
                            teacherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.lightOnSurface,
                            ),
                          ),
                        ),
                        // Group Cards
                        ...groupsData.entries.map((groupEntry) {
                          final groupKey = groupEntry.key;
                          final records = groupEntry.value;
                          final groupParts = groupKey.split('|||');
                          final groupName =
                              groupParts.length > 0 ? groupParts[0] : 'Unknown';
                          final levelName =
                              groupParts.length > 1 ? groupParts[1] : 'Unknown';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ExpansionTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.lightOnSurface,
                                      ),
                                    ),
                                    Text(
                                      '$levelName • ${records.length} session(s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                children: records
                                    .map((record) =>
                                        _buildAttendanceRecord(record))
                                    .toList(),
                              ),
                            ),
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

  Widget _buildAttendanceRecord(QueryDocumentSnapshot record) {
    final data = record.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt?.toDate().toString().split(' ')[0] ?? 'Unknown';
    final presentCount = (data['presentCount'] as num?)?.toInt() ?? 0;
    final absentCount = (data['absentCount'] as num?)?.toInt() ?? 0;
    final totalStudents = (data['totalStudents'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF667085),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBadge('Total', totalStudents.toString(),
                  AppTheme.lightPrimary),
              _buildStatBadge('Present', presentCount.toString(),
                  const Color(0xFF10B981)),
              _buildStatBadge('Absent', absentCount.toString(),
                  const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, List<QueryDocumentSnapshot>>>
      _groupAttendanceData(List<QueryDocumentSnapshot> docs) {
    final grouped = <String, Map<String, List<QueryDocumentSnapshot>>>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final teacherId = (data['teacherId'] ?? '') as String;
      final groupName = (data['groupName'] ?? 'Unknown Group') as String;
      final levelName = (data['levelName'] ?? 'Unknown Level') as String;

      // Get teacher name from cache
      String teacherName =
          _teacherIdToName[teacherId] ?? 'Unknown Teacher';

      // Check if we need to filter by selected teacher
      if (_selectedTeacher != 'All' && teacherName != _selectedTeacher) {
        continue;
      }

      // Filter by search query
      final searchLower = _searchQuery.toLowerCase();
      if (searchLower.isNotEmpty &&
          !teacherName.toLowerCase().contains(searchLower) &&
          !groupName.toLowerCase().contains(searchLower) &&
          !levelName.toLowerCase().contains(searchLower)) {
        continue;
      }

      grouped.putIfAbsent(teacherName, () => {});
      final groupKey = '$groupName|||$levelName';
      grouped[teacherName]!.putIfAbsent(groupKey, () => []);
      grouped[teacherName]![groupKey]!.add(doc);
    }

    return grouped;
  }
}
