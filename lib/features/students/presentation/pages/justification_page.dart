import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test/features/students/models/absence_feature_model.dart';

class JustificationPage extends StatefulWidget {
  const JustificationPage({
    required this.absence,
    super.key,
  });

  final AbsenceFeatureModel absence;

  @override
  State<JustificationPage> createState() => _JustificationPageState();
}

class _JustificationPageState extends State<JustificationPage> {
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedReason;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  
  final List<String> _reasons = ['Medical', 'Family', 'Personal', 'Other'];
  final List<IconData> _reasonIcons = [
    Icons.medical_services_outlined,
    Icons.family_restroom_outlined,
    Icons.person_outline,
    Icons.more_horiz,
  ];

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        
        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 5MB')),
            );
          }
          return;
        }

        setState(() => _selectedFile = file);
        print('[JustificationPage] File selected: ${file.name} (${file.size} bytes)');
      }
    } catch (e) {
      print('[JustificationPage] Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      return null;
    }

    try {
      print('[JustificationPage] Uploading file: ${_selectedFile!.name}');
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final fileName =
          '${currentUser.uid}/${widget.absence.id}/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';
      final ref = _storage.ref().child('justifications/$fileName');
      
      final task = await ref.putData(
        _selectedFile!.bytes!,
        SettableMetadata(contentType: _selectedFile!.extension),
      );
      
      final url = await task.ref.getDownloadURL();
      print('[JustificationPage] File uploaded successfully: $url');
      return url;
    } catch (e) {
      print('[JustificationPage] Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _submitJustification() async {
    // Validation
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for absence')),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a supporting document')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('[JustificationPage] Starting justification submission...');
      print('[JustificationPage] Student ID: ${currentUser.uid}');
      print('[JustificationPage] Absence ID: ${widget.absence.id}');
      print('[JustificationPage] Reason: $_selectedReason');

      // Upload file
      final fileUrl = await _uploadFile();

      print('[JustificationPage] File URL: $fileUrl');

      // Create justification document
      await _firestore.collection('justifications').add({
        'studentId': currentUser.uid,
        'absenceId': widget.absence.id,
        'subjectName': widget.absence.subjectName,
        'teacherName': widget.absence.teacherName,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'fileUrl': fileUrl,
        'fileType': _selectedFile!.extension,
        'fileName': _selectedFile!.name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      print('[JustificationPage] Justification document created');

      // Update absence status to submitted
      await _firestore
          .collection('absences')
          .doc(widget.absence.id)
          .update({
            'status': 'justified',
            'justificationSubmittedAt': FieldValue.serverTimestamp(),
          });

      print('[JustificationPage] Absence status updated to justified');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Justification submitted successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('[JustificationPage] Error submitting justification: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
        title: const Text(
          'Submit Justification',
          style: TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ABSENCE INFO CARD
            _buildAbsenceInfoCard(),
            const SizedBox(height: 24),

            // 2. WHY WERE YOU ABSENT?
            _buildReasonSection(),
            const SizedBox(height: 24),

            // 3. ADDITIONAL DETAILS
            _buildAdditionalDetailsSection(),
            const SizedBox(height: 24),

            // 4. SUPPORTING DOCUMENTS
            _buildSupportingDocumentsSection(),
            const SizedBox(height: 24),

            // 5. SUBMIT BUTTON
            _buildSubmitButton(),
            const SizedBox(height: 16),

            // Disclaimer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'BY SUBMITTING, YOU CONFIRM THE INFORMATION PROVIDED IS ACCURATE AND AUTHENTIC.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsenceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFD92D20), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ABSENCE DETAILS',
            style: TextStyle(
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.absence.subjectName,
            style: const TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'UNJUSTIFIED',
                  style: TextStyle(
                    color: Color(0xFFD92D20),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFF667085)),
              const SizedBox(width: 8),
              Text(
                _formatDate(widget.absence.createdAt),
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.class_outlined,
                  size: 16, color: Color(0xFF667085)),
              const SizedBox(width: 8),
              Text(
                'Absence Type: ${widget.absence.courseCode}',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF667085)),
              const SizedBox(width: 8),
              Text(
                'Duration: 2 Hours',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why were you absent?',
          style: TextStyle(
            color: Color(0xFF1D2939),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reasons.length,
          itemBuilder: (context, index) {
            final reason = _reasons[index];
            final isSelected = _selectedReason == reason;

            return GestureDetector(
              onTap: () => setState(() => _selectedReason = reason),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEEE5FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF5A4CF0)
                        : const Color(0xFFE4E7EC),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _reasonIcons[index],
                      size: 32,
                      color: isSelected
                          ? const Color(0xFF5A4CF0)
                          : const Color(0xFF98A2B3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF5A4CF0)
                            : const Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details',
          style: TextStyle(
            color: Color(0xFF1D2939),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _detailsController,
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Please describe the circumstances regarding your absence...',
            hintStyle: const TextStyle(
              color: Color(0xFFC0C5D0),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF5A4CF0),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(color: Color(0xFF1D2939)),
        ),
      ],
    );
  }

  Widget _buildSupportingDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supporting Documents',
          style: TextStyle(
            color: Color(0xFF1D2939),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isSubmitting ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD6D9E3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Column(
              children: [
                if (_selectedFile == null)
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E5FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF5A4CF0),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload medical certificate or notice',
                        style: TextStyle(
                          color: Color(0xFF1D2939),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PDF, JPG, or PNG (Max 5MB)',
                        style: TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF12B76A),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(
                          color: Color(0xFF1D2939),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB',
                        style: const TextStyle(
                          color: Color(0xFF98A2B3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitJustification,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5A4CF0),
          disabledBackgroundColor: const Color(0xFFBBB6F0),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Justification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
