import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:test/pages/departement/AddSubject.dart';
import 'package:test/pages/departement/ViewExclude.dart';
import 'package:test/pages/departement/AddTeacher.dart';
import 'package:test/pages/departement/common_widgets.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:test/services/firestore_service.dart';
import 'departement/AddStudent.dart';

class DepartmentDashboard extends StatefulWidget {
  const DepartmentDashboard({super.key});

  @override
  State<DepartmentDashboard> createState() => _DepartmentDashboardState();
}

class _DepartmentDashboardState extends State<DepartmentDashboard> {
  final String universityName = 'Ain Témouchent University - UBBAT';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentManagementProvider>().initializeBaseData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: departmentAppBar(context, context.tr('dashboard')),
      drawer: departmentDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildHeader(context, provider),
            const SizedBox(height: 20),
            _buildQuickStats(context, provider),
            const SizedBox(height: 20),
            _buildAttendanceOverview(context, provider),
            const SizedBox(height: 30),
            _buildQuickActions(context),
          ],
        ),
      ),
      bottomNavigationBar: departmentBottomNav(context, 0),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    StudentManagementProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF004AC6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: context.isRtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Department Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            universityName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: provider.watchAttendanceOverview(),
            builder: (context, overviewSnapshot) {
              final overview =
                  overviewSnapshot.data ??
                  const AttendanceOverviewStats(
                    totalStudents: 0,
                    averageAttendanceRate: 0,
                    averageAttendancePoints: 0,
                  );

              return StreamBuilder(
                stream: provider.watchTeachers(),
                builder: (context, teachersSnapshot) {
                  final teachers = teachersSnapshot.data ?? const [];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(_formatDate()),
                      _buildInfoChip('${overview.totalStudents} Students'),
                      _buildInfoChip('${teachers.length} Teachers'),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    StudentManagementProvider provider,
  ) {
    return StreamBuilder<AttendanceOverviewStats>(
      stream: provider.watchAttendanceOverview(),
      builder: (context, overviewSnapshot) {
        final overview =
            overviewSnapshot.data ??
            const AttendanceOverviewStats(
              totalStudents: 0,
              averageAttendanceRate: 0,
              averageAttendancePoints: 0,
            );

        return StreamBuilder(
          stream: provider.watchTeachers(),
          builder: (context, teachersSnapshot) {
            final teachers = teachersSnapshot.data ?? const [];
            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    context.tr('students'),
                    overview.totalStudents.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    context.tr('teachers'),
                    teachers.length.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    context.tr('attendance'),
                    _formatRatePercent(overview.averageAttendanceRate),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceOverview(
    BuildContext context,
    StudentManagementProvider provider,
  ) {
    return StreamBuilder<AttendanceOverviewStats>(
      stream: provider.watchAttendanceOverview(),
      builder: (context, snapshot) {
        final overview =
            snapshot.data ??
            const AttendanceOverviewStats(
              totalStudents: 0,
              averageAttendanceRate: 0,
              averageAttendancePoints: 0,
            );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance Overview',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Overall Attendance Rate',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatRatePercent(overview.averageAttendanceRate),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${overview.totalStudents} Students',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (overview.averageAttendanceRate / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Average of all student attendance values stored in Firestore',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.person_add_outlined,
                color: const Color(0xFF2563EB),
                label: 'Add Student',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddStudent()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.school_outlined,
                color: const Color(0xFF7C3AED),
                label: 'Add Teacher',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTeacher()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.menu_book_outlined,
                color: const Color(0xFF059669),
                label: 'Add Subject',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddSubject()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.gpp_maybe_outlined,
                color: const Color(0xFFB54708),
                label: 'View Exclude',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewExclude()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
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
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _formatRatePercent(double rate) {
    final normalized = rate.clamp(0, 100).toDouble();
    return '${normalized.toStringAsFixed(1)}%';
  }
}
