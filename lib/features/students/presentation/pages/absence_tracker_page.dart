import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/absence_feature_model.dart';

class AbsenceTrackerPage extends StatefulWidget {
  const AbsenceTrackerPage({super.key, this.studentId});

  final String? studentId;

  @override
  State<AbsenceTrackerPage> createState() => _AbsenceTrackerPageState();
}

class _AbsenceTrackerPageState extends State<AbsenceTrackerPage> {
  int _bottomIndex = 1;
  late final StudentsFirestoreService _service;

  @override
  void initState() {
    super.initState();
    _service = StudentsFirestoreService();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Use Firebase Auth UID instead of hardcoded 'current_student_id'
    final currentUser = FirebaseAuth.instance.currentUser;
    final studentId = widget.studentId ?? currentUser?.uid ?? '';
    
    if (studentId.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F4FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F4FA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4F46E5)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Absence Tracker',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: Text('Unable to load student data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4F46E5)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Absence Tracker',
          style: TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4F46E5)),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<AbsenceFeatureModel>>(
        stream: _service.watchAbsencesByStudent(studentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final absences = snapshot.data ?? [];
          final submitted = absences
              .where((a) => a.status == AbsenceStatus.justified)
              .length;
          final pending = absences
              .where((a) => a.status == AbsenceStatus.pending)
              .length;
          final total = absences.length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    total: total,
                    submitted: submitted,
                    pending: pending,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Recent Absences',
                          style: TextStyle(
                            fontSize: 36,
                            height: 1,
                            color: Color(0xFF1D2939),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDEE4FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Pending ($pending)',
                          style: const TextStyle(
                            color: Color(0xFF5A5FE8),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (absences.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No absences recorded',
                          style: TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildAbsenceCards(absences),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _AbsenceBottomBar(
        currentIndex: _bottomIndex,
        onTap: (index) => setState(() => _bottomIndex = index),
      ),
    );
  }

  List<Widget> _buildAbsenceCards(List<AbsenceFeatureModel> absences) {
    return absences.map((absence) {
      final status = _determineStatus(absence);
      return _AbsenceCard(
        absence: absence,
        status: status,
        onTapCard: () => _onTapAbsence(absence),
        onJustify: () => _handleJustify(absence),
      );
    }).toList();
  }

  void _onTapAbsence(AbsenceFeatureModel absence) {
    if (absence.status == AbsenceStatus.justified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification already submitted.')),
      );
      return;
    }
    _handleJustify(absence);
  }

  _AbsenceStatus _determineStatus(AbsenceFeatureModel absence) {
    if (absence.status == AbsenceStatus.justified) {
      return _AbsenceStatus.submitted;
    }
    if (absence.status == AbsenceStatus.rejected ||
        absence.remainingMilliseconds <= 0) {
      return _AbsenceStatus.expired;
    }
    if (absence.isUrgent) {
      return _AbsenceStatus.pendingUrgent;
    }
    return _AbsenceStatus.pending;
  }

  Future<void> _handleJustify(AbsenceFeatureModel absence) async {
    if (absence.remainingMilliseconds <= 0 ||
        absence.status != AbsenceStatus.pending) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification time has expired.')),
      );
      return;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _JustificationFormDialog(absence: absence, service: _service),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.submitted,
    required this.pending,
  });

  final int total;
  final int submitted;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4535DA), Color(0xFF5A48F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24453ADA),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL ABSENCES',
            style: TextStyle(
              color: Color(0xFFC7C8FF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'this semester',
                style: TextStyle(
                  color: Color(0xFFE8E9FF),
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _summarySmallCard('SUBMITTED', submitted)),
              const SizedBox(width: 12),
              Expanded(child: _summarySmallCard('PENDING', pending)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summarySmallCard(String title, int value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5A4CF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB9BCFF),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsenceCard extends StatefulWidget {
  const _AbsenceCard({
    required this.absence,
    required this.status,
    required this.onTapCard,
    required this.onJustify,
  });

  final AbsenceFeatureModel absence;
  final _AbsenceStatus status;
  final VoidCallback onTapCard;
  final VoidCallback onJustify;

  @override
  State<_AbsenceCard> createState() => _AbsenceCardState();
}

class _AbsenceCardState extends State<_AbsenceCard> {
  late Future<void> _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _refreshTimer = Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {});
      }
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = widget.status == _AbsenceStatus.expired;
    final isSubmitted = widget.status == _AbsenceStatus.submitted;
    final tint = isExpired ? const Color(0xFFF4F6FB) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: widget.onTapCard,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: _getAccentColor(widget.status),
                width: 3.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEACHER: ${widget.absence.teacherName}',
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.absence.subjectName,
                        style: const TextStyle(
                          color: Color(0xFF1D2939),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _statusIcon(widget.status),
                      color: isExpired
                          ? const Color(0xFF98A2B3)
                          : widget.status == _AbsenceStatus.pendingUrgent
                          ? const Color(0xFFD92D20)
                          : const Color(0xFF7B83FF),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.absence.remainingTimeFormatted,
                  style: TextStyle(
                    color: isExpired
                        ? const Color(0xFF667085)
                        : isSubmitted
                        ? const Color(0xFF12B76A)
                        : widget.status == _AbsenceStatus.pendingUrgent
                        ? const Color(0xFFD92D20)
                        : const Color(0xFF4F46E5),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF667085),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(widget.absence.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        widget.status,
                      ).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusText(widget.status),
                      style: TextStyle(
                        color: _statusColor(widget.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                    border: isExpired
                        ? Border.all(color: const Color(0xFFE4E7EC))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTimeLabel(widget.status),
                              style: const TextStyle(
                                color: Color(0xFF98A2B3),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.absence.remainingTimeFormatted,
                              style: TextStyle(
                                color: isExpired
                                    ? const Color(0xFF667085)
                                    : widget.status ==
                                          _AbsenceStatus.pendingUrgent
                                    ? const Color(0xFFD92D20)
                                    : const Color(0xFF4F46E5),
                                fontSize: 22,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpired
                            ? Icons.block_outlined
                            : widget.status == _AbsenceStatus.pendingUrgent
                            ? Icons.timer_outlined
                            : Icons.schedule,
                        color: isExpired
                            ? const Color(0xFF98A2B3)
                            : widget.status == _AbsenceStatus.pendingUrgent
                            ? const Color(0xFFD92D20)
                            : const Color(0xFF5E64FF),
                      ),
                    ],
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Cannot justify anymore',
                    style: TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (!isExpired && widget.status == _AbsenceStatus.pending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onJustify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.status == _AbsenceStatus.pendingUrgent
                            ? const Color(0xFF4636D9)
                            : const Color(0xFFC9D9F4),
                        foregroundColor:
                            widget.status == _AbsenceStatus.pendingUrgent
                            ? Colors.white
                            : const Color(0xFF667085),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Justify Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAccentColor(_AbsenceStatus status) {
    switch (status) {
      case _AbsenceStatus.pendingUrgent:
        return const Color(0xFFD92D20);
      case _AbsenceStatus.pending:
        return const Color(0xFF7B83FF);
      case _AbsenceStatus.submitted:
      case _AbsenceStatus.expired:
        return const Color(0xFF98A2B3);
    }
  }

  IconData _statusIcon(_AbsenceStatus status) {
    switch (status) {
      case _AbsenceStatus.pendingUrgent:
        return Icons.warning_amber_rounded;
      case _AbsenceStatus.pending:
        return Icons.assignment_late_outlined;
      case _AbsenceStatus.submitted:
        return Icons.check_circle_outlined;
      case _AbsenceStatus.expired:
        return Icons.event_busy_outlined;
    }
  }

  String _getTimeLabel(_AbsenceStatus status) {
    switch (status) {
      case _AbsenceStatus.pendingUrgent:
        return 'DEADLINE COUNTDOWN';
      case _AbsenceStatus.pending:
        return 'TIME TO JUSTIFY';
      case _AbsenceStatus.submitted:
        return 'STATUS';
      case _AbsenceStatus.expired:
        return 'STATUS';
    }
  }

  String _statusText(_AbsenceStatus status) {
    switch (status) {
      case _AbsenceStatus.pendingUrgent:
      case _AbsenceStatus.pending:
        return 'PENDING';
      case _AbsenceStatus.submitted:
        return 'SUBMITTED';
      case _AbsenceStatus.expired:
        return 'EXPIRED';
    }
  }

  Color _statusColor(_AbsenceStatus status) {
    switch (status) {
      case _AbsenceStatus.pendingUrgent:
        return const Color(0xFFD92D20);
      case _AbsenceStatus.pending:
        return const Color(0xFF4F46E5);
      case _AbsenceStatus.submitted:
        return const Color(0xFF12B76A);
      case _AbsenceStatus.expired:
        return const Color(0xFF667085);
    }
  }

  String _formatDateTime(DateTime date) {
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
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $suffix';
  }

  @override
  void dispose() {
    _refreshTimer.ignore();
    super.dispose();
  }
}

class _JustificationFormDialog extends StatefulWidget {
  const _JustificationFormDialog({
    required this.absence,
    required this.service,
  });

  final AbsenceFeatureModel absence;
  final StudentsFirestoreService service;

  @override
  State<_JustificationFormDialog> createState() =>
      _JustificationFormDialogState();
}

class _JustificationFormDialogState extends State<_JustificationFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (!mounted || result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final file = _pickedFile;
    if (file == null || file.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image or PDF file.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.service.submitAbsenceJustification(
        absenceId: widget.absence.id,
        studentId: widget.absence.studentId,
        reason: _reasonController.text,
        fileBytes: file.bytes!,
        fileName: file.name,
        fileType: (file.extension ?? '').toLowerCase(),
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Justification sent to admin.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit justification: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Justification'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Reason is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _pickedFile == null
                        ? 'Upload Image or PDF'
                        : _pickedFile!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Allowed: JPG, PNG, PDF',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }
}

class _AbsenceBottomBar extends StatelessWidget {
  const _AbsenceBottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _barItem(0, Icons.home_rounded, 'HOME'),
          _barItem(1, Icons.event_busy_rounded, 'ABSENCES'),
          _barItem(2, Icons.star_rounded, 'GRADES'),
          _barItem(3, Icons.person_rounded, 'PROFILE'),
        ],
      ),
    );
  }

  Widget _barItem(int index, IconData icon, String label) {
    final active = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8EBFD) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF4F46E5) : const Color(0xFF98A2B3),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFF98A2B3),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AbsenceStatus { pendingUrgent, pending, submitted, expired }
