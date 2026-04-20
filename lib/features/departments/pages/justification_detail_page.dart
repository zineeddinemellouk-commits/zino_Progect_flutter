import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/helpers/localization_helper.dart';

class JustificationDetailPage extends StatefulWidget {
  const JustificationDetailPage({
    required this.justificationId,
    required this.notificationId,
    super.key,
  });

  final String justificationId;
  final String notificationId;

  @override
  State<JustificationDetailPage> createState() =>
      _JustificationDetailPageState();
}

class _JustificationDetailPageState extends State<JustificationDetailPage> {
  late final FirebaseFirestore _firestore;
  bool _isApproving = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  Future<void> _approveJustification(
    Map<String, dynamic> justificationData,
  ) async {
    setState(() => _isApproving = true);

    try {
      final batch = _firestore.batch();

      // Update justification status
      batch.update(
        _firestore.collection('justifications').doc(widget.justificationId),
        {'status': 'approved', 'approvedAt': FieldValue.serverTimestamp()},
      );

      // Update absence status
      final absenceId = justificationData['absenceId'] as String?;
      if (absenceId != null && absenceId.isNotEmpty) {
        batch.update(_firestore.collection('absences').doc(absenceId), {
          'status': 'justified',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('justification_approved')),
            backgroundColor: const Color(0xFF12B76A),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('[JustificationDetailPage] Error approving: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: const Color(0xFFD92D20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  Future<void> _rejectJustification(
    Map<String, dynamic> justificationData,
  ) async {
    setState(() => _isRejecting = true);

    try {
      final batch = _firestore.batch();

      // Update justification status
      batch.update(
        _firestore.collection('justifications').doc(widget.justificationId),
        {'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()},
      );

      // Update absence status back to pending
      final absenceId = justificationData['absenceId'] as String?;
      if (absenceId != null && absenceId.isNotEmpty) {
        batch.update(_firestore.collection('absences').doc(absenceId), {
          'status': 'pending',
          'rejectedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('justification_rejected')),
            backgroundColor: const Color(0xFFD92D20),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('[JustificationDetailPage] Error rejecting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: const Color(0xFFD92D20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F46E5)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr('justification_details'),
          style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore
            .collection('justifications')
            .doc(widget.justificationId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A4CF0)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFD92D20),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('error_loading'),
                    style: const TextStyle(
                      color: Color(0xFFD92D20),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                context.tr('justification_not_found'),
                style: const TextStyle(color: Color(0xFF667085), fontSize: 14),
              ),
            );
          }

          final justificationData =
              snapshot.data!.data() as Map<String, dynamic>;
          final status =
              (justificationData['status'] as String?)?.toLowerCase() ??
              'pending';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                _buildStatusBadge(status),
                const SizedBox(height: 24),

                // Student Info Card
                _buildInfoCard(
                  context,
                  icon: Icons.person_outline,
                  title: context.tr('student'),
                  subtitle: justificationData['studentName'] ?? 'Unknown',
                ),
                const SizedBox(height: 12),

                // Subject Info Card
                _buildInfoCard(
                  context,
                  icon: Icons.book_outlined,
                  title: context.tr('subject'),
                  subtitle: justificationData['subject'] ?? 'Unknown',
                ),
                const SizedBox(height: 12),

                // Reason Info Card
                _buildInfoCard(
                  context,
                  icon: Icons.info_outline,
                  title: context.tr('reason'),
                  subtitle: justificationData['reason'] ?? 'N/A',
                ),
                const SizedBox(height: 24),

                // Absence Date
                Text(
                  context.tr('absence_date'),
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: Text(
                    _formatDate(justificationData['absenceDate']),
                    style: const TextStyle(
                      color: Color(0xFF1D2939),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Supporting Document
                if (justificationData['fileUrl'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('supporting_document'),
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Open file in browser/app
                          final fileUrl =
                              justificationData['fileUrl'] as String;
                          print(
                            '[JustificationDetailPage] Opening file: $fileUrl',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.file_present_outlined,
                                color: Color(0xFF5A4CF0),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      justificationData['fileName'] ??
                                          'document',
                                      style: const TextStyle(
                                        color: Color(0xFF1D2939),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to view',
                                      style: const TextStyle(
                                        color: Color(0xFF667085),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new,
                                color: Color(0xFF5A4CF0),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // Action Buttons (only if pending)
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRejecting
                              ? null
                              : () => _rejectJustification(justificationData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFECEB),
                            disabledBackgroundColor: const Color(0xFFF5EFEB),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: _isRejecting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFFD92D20).withOpacity(0.5),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.close,
                                  color: Color(0xFFD92D20),
                                ),
                          label: Text(
                            context.tr('reject'),
                            style: const TextStyle(
                              color: Color(0xFFD92D20),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isApproving
                              ? null
                              : () => _approveJustification(justificationData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A4CF0),
                            disabledBackgroundColor: const Color(0xFFBBB6F0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: _isApproving
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.check, color: Colors.white),
                          label: Text(
                            context.tr('approve'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, backgroundColor, icon) = switch (status) {
      'approved' => (
        const Color(0xFF12B76A),
        const Color(0xFFE8F5E9),
        Icons.check_circle_outlined,
      ),
      'rejected' => (
        const Color(0xFFD92D20),
        const Color(0xFFFFECEB),
        Icons.cancel_outlined,
      ),
      _ => (
        const Color(0xFFB42318),
        const Color(0xFFFFF6F0),
        Icons.pending_actions_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF5A4CF0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF1D2939),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    DateTime date;
    if (dateValue is Timestamp) {
      date = dateValue.toDate();
    } else if (dateValue is DateTime) {
      date = dateValue;
    } else {
      return 'Unknown';
    }

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
