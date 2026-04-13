import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test/models/justification_model.dart';
import 'package:test/pages/departement/providers/student_management_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VewJustification extends StatelessWidget {
  const VewJustification({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentManagementProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F9FB),
        foregroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Justification Requests',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Justification Requests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<JustificationModel>>(
                stream: provider.watchJustifications(),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? const <JustificationModel>[];
                  final pending = items
                      .where((j) => j.status == 'pending')
                      .length;
                  return Text(
                    '$pending pending requests',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  );
                },
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<JustificationModel>>(
                  stream: provider.watchJustifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final items = snapshot.data ?? const <JustificationModel>[];
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No justifications found.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _JustificationCard(
                          item: item,
                          onTap: () => _showDetails(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
              .updateJustificationStatus(id: item.id, status: 'approved');
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Justification approved')),
            );
          }
        },
        onReject: (reason) async {
          await context
              .read<StudentManagementProvider>()
              .updateJustificationStatus(
                id: item.id,
                status: 'rejected',
                refusalReason: reason,
              );
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Justification rejected')),
            );
          }
        },
      ),
    );
  }
}

class _JustificationCard extends StatelessWidget {
  const _JustificationCard({required this.item, required this.onTap});

  final JustificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = (item.studentName ?? 'Student')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();

    final status = item.status.toLowerCase();
    final statusColor = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.red,
      _ => Colors.orange,
    };
    final statusLabel = switch (status) {
      'approved' => 'APPROVED',
      'rejected' => 'REJECTED',
      _ => 'PENDING',
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.studentName ?? 'Unknown Student',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.subject} • ${item.teacherName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.email ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Absence: ${item.absenceDate.toIso8601String().split('T').first}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.send, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Submitted: ${item.createdAt.toIso8601String().split('T').first}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
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
              Text('${widget.item.subject} • ${widget.item.teacherName}'),
              const SizedBox(height: 8),
              Text(
                'Absence date: ${widget.item.absenceDate.toIso8601String().split('T').first}',
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${widget.item.createdAt.toIso8601String().split('T').first}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(widget.item.reason ?? 'No reason provided.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Attachment',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openFile,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View file'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _refusalReasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (widget.item.status.toLowerCase() == 'pending') ...[
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
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: _isRejecting ? null : widget.onApprove,
            child: const Text('Approve'),
          ),
        ],
      ],
    );
  }
}
