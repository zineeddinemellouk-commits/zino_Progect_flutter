import 'package:flutter/material.dart';
import 'package:test/features/students/services/attendance_service.dart';
import 'package:test/utils/app_theme.dart';

/// Reusable card widget for displaying subject attendance
class SubjectAttendanceCard extends StatelessWidget {
  final SubjectAttendanceModel stats;
  final int index;

  const SubjectAttendanceCard({
    super.key,
    required this.stats,
    required this.index,
  });

  /// Get appropriate icon based on subject name
  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math') || name.contains('algebra') || name.contains('geometry')) {
      return Icons.calculate;
    }
    if (name.contains('english') || name.contains('language') || name.contains('french')) {
      return Icons.language;
    }
    if (name.contains('science') || name.contains('chemistry') || name.contains('biology') || name.contains('physics')) {
      return Icons.science;
    }
    if (name.contains('history') || name.contains('social') || name.contains('geography')) {
      return Icons.history;
    }
    if (name.contains('physical') || name.contains('sport') || name.contains('pe')) {
      return Icons.sports_basketball;
    }
    if (name.contains('art') || name.contains('design') || name.contains('music')) {
      return Icons.palette;
    }
    if (name.contains('computer') || name.contains('technology') || name.contains('it')) {
      return Icons.computer;
    }
    return Icons.subject;
  }

  /// Get background color based on attendance level
  Color _getBackgroundColor() {
    if (stats.isLowAttendance) {
      return const Color(0xFFFFEBEE); // Light red
    }
    if (index == 0) {
      return const Color(0xFFE8F5E9); // Light green for best attendance
    }
    return Colors.white;
  }

  /// Get icon background color
  Color _getIconBackgroundColor() {
    return stats.isLowAttendance
        ? const Color(0xFFEF5350).withValues(alpha: 0.1)
        : const Color(0xFF2563EB).withValues(alpha: 0.1);
  }

  /// Get icon color
  Color _getIconColor() {
    return stats.isLowAttendance
        ? const Color(0xFFEF5350)
        : AppTheme.lightPrimary;
  }

  /// Get progress bar color based on percentage
  Color _getProgressBarColor() {
    if (stats.attendancePercentage < 70) {
      return const Color(0xFFEF5350); // Red
    }
    if (stats.attendancePercentage < 85) {
      return const Color(0xFFFFA726); // Orange
    }
    return const Color(0xFF4CAF50); // Green
  }

  @override
  Widget build(BuildContext context) {
    const double progressBarHeight = 8;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: stats.isLowAttendance
              ? const BorderSide(
                  color: Color(0xFFEF5350),
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        elevation: 3,
        color: _getBackgroundColor(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Subject Icon, Name, and Teacher
              Row(
                children: [
                  // Circular Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getIconBackgroundColor(),
                    ),
                    child: Icon(
                      _getSubjectIcon(stats.subjectName),
                      color: _getIconColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Subject Name & Teacher Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.subjectName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'with ${stats.teacherName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 2: Attendance Stats (Present/Absent)
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      label: 'Present',
                      value: stats.totalPresent.toString(),
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatColumn(
                      label: 'Absent',
                      value: stats.totalAbsent.toString(),
                      color: const Color(0xFFEF5350),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // SECTION 3: Progress Bar & Percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Text(
                        '${stats.attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _getProgressBarColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.attendancePercentage / 100,
                      minHeight: progressBarHeight,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressBarColor(),
                      ),
                    ),
                  ),
                ],
              ),

              // SECTION 4: Low Attendance Warning Badge
              if (stats.isLowAttendance)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_outlined,
                          size: 16,
                          color: Color(0xFFEF5350),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Low attendance - Try to improve',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF5350),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for displaying stat columns (Present/Absent)
  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
