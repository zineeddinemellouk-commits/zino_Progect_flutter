import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:test/features/students/models/absence_feature_model.dart';
import 'package:test/helpers/localization_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JustificationPage extends StatefulWidget {
  const JustificationPage({required this.absence, super.key});

  final AbsenceFeatureModel absence;

  @override
  State<JustificationPage> createState() => _JustificationPageState();
}

class _JustificationPageState extends State<JustificationPage> {
  late final FirebaseFirestore _firestore;

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
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      print('[JustificationPage] Starting file picker...');
      print('[JustificationPage] Platform: ${kIsWeb ? 'WEB' : 'NATIVE'}');

      // On web, we need withData: true to get bytes; on native, withData: false to get path
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: kIsWeb, // true on web, false on native
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        print(
          '[JustificationPage] File picked - Name: ${file.name}, Size: ${file.size}',
        );

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          print(
            '[JustificationPage] ERROR: File size ${file.size} exceeds 5MB limit',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('file_too_large'))),
            );
          }
          return;
        }

        // On web, validate bytes are available; on native, validate path exists
        if (kIsWeb) {
          if (file.bytes == null || file.bytes!.isEmpty) {
            print('[JustificationPage] ERROR: File bytes are null or empty');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('invalid_file_data'))),
              );
            }
            return;
          }
          print(
            '[JustificationPage] ✓ Web file loaded: ${file.name} (${file.bytes!.length} bytes)',
          );
        } else {
          if (file.path == null || file.path!.isEmpty) {
            print('[JustificationPage] ERROR: File path is null or empty');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('invalid_file_path'))),
              );
            }
            return;
          }

          // Validate file actually exists on native platforms
          final fileExists = await File(file.path!).exists();
          if (!fileExists) {
            print(
              '[JustificationPage] ERROR: File does not exist at path: ${file.path}',
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('file_not_found'))),
              );
            }
            return;
          }
          print(
            '[JustificationPage] ✓ Native file selected: ${file.name} (${file.size} bytes)',
          );
        }

        setState(() => _selectedFile = file);
        print(
          '[JustificationPage] ✓ File ready: ${file.name} (${file.size} bytes)',
        );
      } else {
        print('[JustificationPage] File picker cancelled or no file selected');
      }
    } catch (e) {
      print('[JustificationPage] ERROR picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('pick_file_error')}: $e')),
        );
      }
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) {
      print('[JustificationPage] ⚠️ ABORT UPLOAD: No file selected');
      return null;
    }

    try {
      final fileName = _selectedFile!.name;
      Uint8List fileBytes;

      print('[JustificationPage] 📤 STARTING FILE UPLOAD');
      print('[JustificationPage]   File name: $fileName');
      print('[JustificationPage]   File size: ${_selectedFile!.size} bytes');
      print('[JustificationPage]   Platform: ${kIsWeb ? 'WEB' : 'NATIVE'}');

      // Get file bytes based on platform
      if (kIsWeb) {
        // On web, use bytes directly from file picker
        if (_selectedFile!.bytes == null || _selectedFile!.bytes!.isEmpty) {
          throw Exception('Web file bytes are null or empty');
        }
        fileBytes = _selectedFile!.bytes!;
        print(
          '[JustificationPage]   ✓ Using bytes from web picker (${fileBytes.length} bytes)',
        );
      } else {
        // On native platforms, read bytes from file path
        if (_selectedFile!.path == null || _selectedFile!.path!.isEmpty) {
          throw Exception('Native file path is null or empty');
        }
        final file = File(_selectedFile!.path!);
        final fileExists = await file.exists();
        if (!fileExists) {
          throw Exception(
            'Local file does not exist at: ${_selectedFile!.path}',
          );
        }
        fileBytes = await file.readAsBytes();
        print(
          '[JustificationPage]   ✓ Read ${fileBytes.length} bytes from native path',
        );
      }

      // Get authenticated user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      print('[JustificationPage]   Student UID: ${currentUser.uid}');

      // Create unique storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      const bucketName = 'justifications'; // Your Supabase storage bucket name
      final uniqueFileName =
          '${currentUser.uid}/${widget.absence.id}/${timestamp}_$fileName';

      print('[JustificationPage]   Storage path: $bucketName/$uniqueFileName');

      // Upload to Supabase Storage
      print('[JustificationPage]   📝 Uploading to Supabase Storage...');
      final mimeType = _getMimeType(_selectedFile!.extension ?? 'pdf');
      final supabase = Supabase.instance.client;

      final uploadResponse = await supabase.storage
          .from(bucketName)
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      if (uploadResponse.isEmpty) {
        throw Exception('Upload failed: empty response');
      }

      print('[JustificationPage]   ✓ Upload completed');

      // Get public URL
      print('[JustificationPage]   🔗 Fetching public URL...');
      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(uniqueFileName);
      print('[JustificationPage]   ✓ Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('[JustificationPage] ❌ ERROR UPLOADING FILE: $e');
      return null;
    }
  }

  Future<void> _submitJustification() async {
    // ========== STEP 1: VALIDATION ==========
    print(
      '\n[JustificationPage] ========== STARTING JUSTIFICATION SUBMISSION ==========',
    );

    if (_selectedReason == null) {
      print('[JustificationPage] ❌ VALIDATION FAILED: No reason selected');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('select_reason'))));
      }
      return;
    }
    print('[JustificationPage] ✓ Reason selected: $_selectedReason');

    if (_selectedFile == null) {
      print('[JustificationPage] ❌ VALIDATION FAILED: No file selected');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('upload_document'))));
      }
      return;
    }
    print('[JustificationPage] ✓ File selected: ${_selectedFile!.name}');

    setState(() => _isSubmitting = true);

    try {
      // ========== STEP 2: AUTHENTICATE ==========
      print('[JustificationPage] Step 1: Getting current user...');
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('❌ User not authenticated');
      }
      print('[JustificationPage] ✓ Authenticated as: ${currentUser.uid}');

      // ========== STEP 3: FETCH STUDENT INFORMATION ==========
      print('[JustificationPage] Step 2: Fetching student information...');
      final studentQuery = await _firestore
          .collection('students')
          .where('authUid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      if (studentQuery.docs.isEmpty) {
        throw Exception('❌ Student profile not found');
      }
      final studentDoc = studentQuery.docs.first;
      final studentData = studentDoc.data();
      final studentName =
          studentData['fullName'] as String? ?? 'Unknown Student';
      final levelId = studentData['levelId'] as String? ?? '';
      final groupId = studentData['groupId'] as String? ?? '';

      // Resolve level and group names
      final levelName = await _resolveName(
        _firestore.collection('levels'),
        levelId,
        fallback: levelId,
      );
      final groupName = await _resolveName(
        _firestore.collection('groups'),
        groupId,
        fallback: groupId,
      );

      print('[JustificationPage] ✓ Student: $studentName');
      print('[JustificationPage] ✓ Level: $levelName');
      print('[JustificationPage] ✓ Group: $groupName');

      // ========== STEP 4: LOG SUBMISSION DETAILS ==========
      print('[JustificationPage] Step 3: Submission details:');
      print('[JustificationPage]   Student ID: ${studentDoc.id}');
      print('[JustificationPage]   Auth UID: ${currentUser.uid}');
      print('[JustificationPage]   Absence ID: ${widget.absence.id}');
      print('[JustificationPage]   Reason: $_selectedReason');
      print('[JustificationPage]   Details: ${_detailsController.text.trim()}');
      print('[JustificationPage]   File: ${_selectedFile!.name}');

      // ========== STEP 5: UPLOAD FILE TO SUPABASE STORAGE ==========
      print(
        '[JustificationPage] Step 4: Uploading file to Supabase Storage...',
      );
      final fileUrl = await _uploadFile();

      if (fileUrl == null || fileUrl.isEmpty) {
        throw Exception('❌ Failed to get download URL after upload');
      }
      print('[JustificationPage] ✓ File uploaded successfully');
      print('[JustificationPage]   URL: $fileUrl');

      // ========== STEP 6: CREATE JUSTIFICATION DOCUMENT IN FIRESTORE ==========
      print(
        '[JustificationPage] Step 5: Creating justification document in Firestore...',
      );

      final justificationData = {
        'studentId': currentUser.uid,
        'studentName': studentName,
        'levelName': levelName,
        'groupName': groupName,
        'absenceId': widget.absence.id,
        'subjectName': widget.absence.subjectName,
        'teacherName': widget.absence.teacherName,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'fileUrl': fileUrl,
        'fileType': _selectedFile!.extension ?? 'unknown',
        'fileName': _selectedFile!.name,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      };

      print('[JustificationPage]   Document data: $justificationData');

      final justificationRef = await _firestore
          .collection('justifications')
          .add(justificationData);
      print('[JustificationPage] ✓ Justification document created');
      print('[JustificationPage]   Document ID: ${justificationRef.id}');

      // ========== STEP 7: UPDATE ABSENCE STATUS IN FIRESTORE ==========
      print(
        '[JustificationPage] Step 6: Updating absence status to "justified"...',
      );

      final absenceUpdateData = {
        'status': 'justified',
        'justificationSubmittedAt': FieldValue.serverTimestamp(),
        'justificationId':
            justificationRef.id, // Link to justification document
      };

      print('[JustificationPage]   Update data: $absenceUpdateData');

      await _firestore
          .collection('absences')
          .doc(widget.absence.id)
          .update(absenceUpdateData);

      print('[JustificationPage] ✓ Absence status updated to "justified"');

      // ========== STEP 7: SUCCESS ==========
      print(
        '[JustificationPage] ✅ JUSTIFICATION SUBMISSION COMPLETED SUCCESSFULLY',
      );
      print('[JustificationPage] ========== END OF SUBMISSION ==========\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('submit_success')),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF12B76A),
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('[JustificationPage] ❌ ERROR DURING SUBMISSION: $e');
      print('[JustificationPage] ========== SUBMISSION FAILED ==========\n');

      if (mounted) {
        setState(() => _isSubmitting = false);

        String errorMessage;
        if (e.toString().contains('object-not-found')) {
          errorMessage = context.tr('upload_file_failed');
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = context.tr('permission_denied');
        } else if (e.toString().contains('not authenticated')) {
          errorMessage = context.tr('please_login');
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error_submit')}: $errorMessage'),
            duration: const Duration(seconds: 4),
            backgroundColor: const Color(0xFFD92D20),
          ),
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
        title: Text(
          context.tr('submit_justification'),
          style: const TextStyle(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.tr('confirmed_accurate'),
                style: const TextStyle(
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
          Text(
            context.tr('absence_details'),
            style: const TextStyle(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.tr('unjustified'),
                  style: const TextStyle(
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
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF667085),
              ),
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
              const Icon(
                Icons.class_outlined,
                size: 16,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 8),
              Text(
                '${context.tr('absence_type')}: ${widget.absence.courseCode}',
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
              const Icon(
                Icons.timer_outlined,
                size: 16,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 8),
              Text(
                '${context.tr('duration')}: 2 Hours',
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
        Text(
          context.tr('why_absent'),
          style: const TextStyle(
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
                  color: isSelected ? const Color(0xFFEEE5FF) : Colors.white,
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
                      context.tr(reason.toLowerCase()),
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
        Text(
          context.tr('additional_details'),
          style: const TextStyle(
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
            hintText: context.tr('describe_absence'),
            hintStyle: const TextStyle(color: Color(0xFFC0C5D0), fontSize: 14),
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
              borderSide: const BorderSide(color: Color(0xFF5A4CF0), width: 2),
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
        Text(
          context.tr('supporting_documents'),
          style: const TextStyle(
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
                      Text(
                        context.tr('upload_certificate'),
                        style: const TextStyle(
                          color: Color(0xFF1D2939),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('file_format'),
                        style: const TextStyle(
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
            : Text(
                context.tr('submit_justification'),
                style: const TextStyle(
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

  Future<String> _resolveName(
    CollectionReference collection,
    String id, {
    required String fallback,
  }) async {
    if (id.trim().isEmpty) return fallback;
    final snap = await collection.doc(id).get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>?;
      return data?['name'] as String? ?? fallback;
    }
    return fallback;
  }
}
