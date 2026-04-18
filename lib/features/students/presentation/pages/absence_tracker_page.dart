import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/students/data/students_firestore_service.dart';
import 'package:test/features/students/models/absence_feature_model.dart';
import 'package:test/features/students/presentation/pages/justification_page.dart';

class AbsenceTrackerPage extends StatefulWidget {
  const AbsenceTrackerPage({super.key});

  @override
  State<AbsenceTrackerPage> createState() => _AbsenceTrackerPageState();
}

class _AbsenceTrackerPageState extends State<AbsenceTrackerPage> {
  late final StudentsFirestoreService _service;
  late final FirebaseFirestore _firestore;

  @override
  void initState() {
    super.initState();
    _service = StudentsFirestoreService();
    _firestore = FirebaseFirestore.instance;
  }

  @override
  Widget build(BuildContext context) {
    // Get current user from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    final studentId = currentUser?.uid ?? '';

    print('[AbsenceTrackerPage] Current user UID: $studentId');
    print('[AbsenceTrackerPage] Current user email: ${currentUser?.email}');

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
          child: Text('Unable to load student data - No user logged in'),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('absences')
            .where('studentId', isEqualTo: studentId)
            .snapshots(),
        builder: (context, snapshot) {
          print('═══════════════════════════════════════════════════════');
          print('[AbsenceTrackerPage] Stream state: ${snapshot.connectionState}');
          print('[AbsenceTrackerPage] Current studentId: $studentId');
          print('[AbsenceTrackerPage] Has error: ${snapshot.hasError}');
          print('[AbsenceTrackerPage] Has data: ${snapshot.hasData}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            print('[AbsenceTrackerPage] ⏳ WAITING for data...');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('[AbsenceTrackerPage] ❌ Stream error: ${snapshot.error}');
            print('[AbsenceTrackerPage] Stack trace: ${snapshot.stackTrace}');
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text('Error loading absences'),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          print('[AbsenceTrackerPage] ✅ Fetched ${docs.length} documents');

          if (docs.isEmpty) {
            print('[AbsenceTrackerPage] ⚠️  No documents found for studentId: $studentId');
            print('[AbsenceTrackerPage] Attempting to fetch ALL absences to debug...');
            
            // Debug: Try to fetch all absences without filter
            _firestore.collection('absences').get().then((snapshot) {
              print('[AbsenceTrackerPage] DEBUG: Total absences in collection: ${snapshot.docs.length}');
              for (var doc in snapshot.docs) {
                print('[AbsenceTrackerPage]   - Doc: ${doc.id}, studentId: ${doc.data()['studentId']}, status: ${doc.data()['status']}');
              }
            });
          }

          // Parse absences from Firestore documents
          List<AbsenceFeatureModel> absences = [];
          for (var doc in docs) {
            try {
              print('[AbsenceTrackerPage] Parsing doc ${doc.id}...');
              final data = doc.data();
              print('[AbsenceTrackerPage]   - Data: $data');
              final absence = AbsenceFeatureModel.fromMap(doc.id, data);
              print('[AbsenceTrackerPage]   ✅ Parsed: ${absence.subjectName} (${absence.status})');
              absences.add(absence);
            } catch (e) {
              print('[AbsenceTrackerPage]   ❌ ERROR parsing doc: $e');
              print('[AbsenceTrackerPage]   Stack: ${StackTrace.current}');
            }
          }

          // Sort locally by createdAt (most recent first)
          absences.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('[AbsenceTrackerPage] 📊 Parsed and sorted ${absences.length} absences successfully');

          // Calculate statistics
          final totalAbsences = absences.length;
          final justifiedAbsences = absences
              .where((a) => a.status == AbsenceStatus.justified)
              .length;
          final pendingAbsences = absences
              .where((a) => a.status == AbsenceStatus.pending)
              .length;

          print('[AbsenceTrackerPage] 📈 Stats - Total: $totalAbsences, Justified: $justifiedAbsences, Pending: $pendingAbsences');
          print('═══════════════════════════════════════════════════════');

          if (absences.isEmpty) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCard(
                      total: 0,
                      justified: 0,
                      pending: 0,
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Recent Absences',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1,
                        color: Color(0xFF1D2939),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DEBUG INFO (No absences found)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Student ID: $studentId', style: const TextStyle(fontSize: 12)),
                          Text('Documents fetched: ${docs.length}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          const Text(
                            'Possible reasons:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Text('1. No absences created for this student yet', style: TextStyle(fontSize: 11)),
                          const Text('2. Student ID mismatch in Firestore', style: TextStyle(fontSize: 11)),
                          const Text('3. Check Firestore console for data', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(
                    total: totalAbsences,
                    justified: justifiedAbsences,
                    pending: pendingAbsences,
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
                          'Pending ($pendingAbsences)',
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
                  ...absences.map((absence) {
                    return _AbsenceCard(
                      absence: absence,
                      service: _service,
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Absence Tracker v1.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics Summary Card (Top Section)
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.justified,
    required this.pending,
  });

  final int total;
  final int justified;
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
              Expanded(
                child: _SummaryBadge(label: 'SUBMITTED', value: justified),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryBadge(label: 'PENDING', value: pending),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual badge for summary card
class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
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
            label,
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

/// Individual Absence Card
class _AbsenceCard extends StatefulWidget {
  const _AbsenceCard({
    required this.absence,
    required this.service,
  });

  final AbsenceFeatureModel absence;
  final StudentsFirestoreService service;

  @override
  State<_AbsenceCard> createState() => _AbsenceCardState();
}

class _AbsenceCardState extends State<_AbsenceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _startTimerUpdate();
  }

  void _startTimerUpdate() {
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _timerController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  bool get _isExpired =>
      widget.absence.status == AbsenceStatus.rejected ||
      widget.absence.remainingMilliseconds <= 0;

  bool get _isUrgent =>
      !_isExpired &&
      widget.absence.isUrgent &&
      widget.absence.status == AbsenceStatus.pending;

  bool get _isJustified => widget.absence.status == AbsenceStatus.justified;

  Future<String?> _fetchJustificationStatus() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('justifications')
          .where('absenceId', isEqualTo: widget.absence.id)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) return null;
      return query.docs.first.data()['status'] as String?;
    } catch (e) {
      print('[AbsenceCard] Error fetching justification: $e');
      return null;
    }
  }

  Color get _borderColor {
    if (_isExpired) return const Color(0xFF98A2B3);
    if (_isJustified) return const Color(0xFF12B76A);
    if (_isUrgent) return const Color(0xFFD92D20);
    return const Color(0xFF7B83FF);
  }

  Color get _statusColor {
    if (_isExpired) return const Color(0xFF667085);
    if (_isJustified) return const Color(0xFF12B76A);
    if (_isUrgent) return const Color(0xFFD92D20);
    return const Color(0xFF4F46E5);
  }

  String get _statusLabel {
    if (_isExpired) return 'EXPIRED';
    if (_isJustified) return 'SUBMITTED';
    if (_isUrgent) return 'PENDING';
    return 'PENDING';
  }

  String get _timeLabel {
    if (_isExpired) return 'STATUS';
    if (_isJustified) return 'STATUS';
    if (_isUrgent) return 'DEADLINE COUNTDOWN';
    return 'TIME TO JUSTIFY';
  }

  @override
  Widget build(BuildContext context) {
    final tint = _isExpired ? const Color(0xFFF4F6FB) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: _borderColor,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course code and optional warning icon
          Row(
            children: [
              Expanded(
                child: Text(
                  'COURSE CODE: ${widget.absence.courseCode}',
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              if (_isUrgent)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD92D20),
                  size: 20,
                )
              else if (_isJustified)
                const Icon(
                  Icons.check_circle_outlined,
                  color: Color(0xFF12B76A),
                  size: 20,
                )
              else if (_isExpired)
                const Icon(
                  Icons.event_busy_outlined,
                  color: Color(0xFF98A2B3),
                  size: 20,
                )
              else
                const Icon(
                  Icons.assignment_late_outlined,
                  color: Color(0xFF7B83FF),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Subject name
          Text(
            widget.absence.subjectName,
            style: const TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Date and time
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
          // Status badge
          FutureBuilder<String?>(
            future: _fetchJustificationStatus(),
            builder: (context, snapshot) {
              String displayLabel = _statusLabel;
              Color statusColor = _statusColor;
              
              // If justified, show the actual justification status
              if (_isJustified && snapshot.hasData && snapshot.data != null) {
                final justStatus = snapshot.data!.toLowerCase();
                if (justStatus == 'accepted') {
                  displayLabel = 'ACCEPTED';
                  statusColor = const Color(0xFF12B76A);
                } else if (justStatus == 'refused') {
                  displayLabel = 'REFUSED';
                  statusColor = const Color(0xFFD92D20);
                } else if (justStatus == 'submitted') {
                  displayLabel = 'SUBMITTED';
                  statusColor = const Color(0xFFF59E0B);
                }
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Timer section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: _isExpired ? const Color(0xFFF9FAFB) : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
              border: _isExpired
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
                        _timeLabel,
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
                          color: _statusColor,
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpired
                      ? Icons.block_outlined
                      : _isUrgent
                          ? Icons.timer_outlined
                          : Icons.schedule,
                  color: _isExpired
                      ? const Color(0xFF98A2B3)
                      : _isUrgent
                          ? const Color(0xFFD92D20)
                          : const Color(0xFF5E64FF),
                  size: 28,
                ),
              ],
            ),
          ),
          // Expired message or Justify button
          if (_isExpired) ...[
            const SizedBox(height: 10),
            const Text(
              'Cannot justify anymore',
              style: TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ] else if (!_isJustified) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleJustify(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUrgent
                      ? const Color(0xFF4636D9)
                      : const Color(0xFFC9D9F4),
                  foregroundColor: _isUrgent
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleJustify(BuildContext context) async {
    if (_isExpired || _isJustified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot justify this absence.'),
        ),
      );
      return;
    }

    // Navigate to JustificationPage
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JustificationPage(absence: widget.absence),
      ),
    );

    // Refresh the page if justification was submitted
    if (result == true && mounted) {
      // The StreamBuilder will automatically update when Firestore data changes
      print('[AbsenceCard] Justification submitted, page will refresh automatically');
    }
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $suffix';
  }
}


