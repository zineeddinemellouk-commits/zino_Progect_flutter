import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/departments/models/department_notification_model.dart';

class DepartmentNotificationService {
  DepartmentNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('department_notifications');

  CollectionReference<Map<String, dynamic>> get _justifications =>
      _firestore.collection('justifications');

  /// Create a notification for department when justification is submitted
  Future<String> createJustificationNotification({
    required String departmentId,
    required String studentId,
    required String studentName,
    required String justificationId,
    required String absenceId,
    required String subjectName,
    String? photoUrl,
  }) async {
    final doc = _notifications.doc();
    await doc.set({
      'departmentId': departmentId.trim(),
      'studentId': studentId.trim(),
      'studentName': studentName.trim(),
      'justificationId': justificationId.trim(),
      'absenceId': absenceId.trim(),
      'subjectName': subjectName.trim(),
      'type': 'justificationsubmitted',
      'title': 'New Justification Request',
      'message': '$studentName submitted a justification for $subjectName',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
      if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl.trim(),
    });
    return doc.id;
  }

  /// Watch all notifications for a department in real-time
  Stream<List<DepartmentNotificationModel>> watchNotificationsByDepartment(
    String departmentId,
  ) {
    final normalizedDepartmentId = departmentId.trim();
    if (normalizedDepartmentId.isEmpty) {
      return Stream.value(const <DepartmentNotificationModel>[]);
    }

    return _notifications
        .where('departmentId', isEqualTo: normalizedDepartmentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    DepartmentNotificationModel.fromMap(doc.id, doc.data()),
              )
              .toList();
        });
  }

  /// Get unread count for department
  Stream<int> watchUnreadNotificationCount(String departmentId) {
    final normalizedDepartmentId = departmentId.trim();
    if (normalizedDepartmentId.isEmpty) {
      return Stream.value(0);
    }

    return _notifications
        .where('departmentId', isEqualTo: normalizedDepartmentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String departmentId) async {
    final normalizedDepartmentId = departmentId.trim();
    if (normalizedDepartmentId.isEmpty) return;

    final snapshot = await _notifications
        .where('departmentId', isEqualTo: normalizedDepartmentId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Get justification details
  Future<Map<String, dynamic>> getJustificationDetails(
    String justificationId,
  ) async {
    final doc = await _justifications.doc(justificationId).get();
    if (!doc.exists) {
      throw Exception('Justification not found');
    }
    return doc.data() ?? {};
  }

  /// Listen to justifications for automatic notification creation
  /// This should be called when department goes online
  void listenToNewJustifications(
    String departmentId,
    Function(String justificationId, Map<String, dynamic> data)
    onNewJustification,
  ) {
    _justifications
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            onNewJustification(doc.id, data);
          }
        });
  }
}
