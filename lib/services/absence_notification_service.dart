import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class AbsenceNotificationService {
  static final AbsenceNotificationService _instance =
      AbsenceNotificationService._internal();

  factory AbsenceNotificationService() {
    return _instance;
  }

  AbsenceNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting notifications permission: $e');
      return false;
    }
  }

  /// Send absence notification to a student
  Future<void> sendAbsenceNotification({
    required String studentName,
    required String subjectName,
    required String teacherName,
    required String absenceId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'absence_channel_id',
        'Absence Notifications',
        channelDescription:
            'Notifications for attendance absence records',
        importance: Importance.high,
        priority: Priority.high,
        autoCancel: true,
        showWhen: true,
      );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails =
          NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      final int notificationId = absenceId.hashCode % 100000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Absence Recorded',
        'You were marked absent in $subjectName by $teacherName',
        notificationDetails,
        payload: absenceId,
      );

      debugPrint('Absence notification sent to $studentName for $subjectName');
    } catch (e) {
      debugPrint('Error sending absence notification: $e');
    }
  }

  Future<void> _showNotification({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String title,
    required String body,
    required int notificationId,
    required String payload,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      showWhen: true,
    );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Send justification status notification to a student.
  Future<void> sendJustificationStatusNotification({
    required String studentName,
    required String subjectName,
    required String teacherName,
    required String justificationId,
    required bool isAccepted,
    String? refusalReason,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final title = isAccepted
          ? 'Justification Accepted'
          : 'Justification Refused';
      final body = isAccepted
          ? 'Your justification for $subjectName with $teacherName was accepted.'
          : 'Your justification for $subjectName with $teacherName was refused.';
      final fullBody = (refusalReason != null && refusalReason.trim().isNotEmpty)
          ? '$body Reason: ${refusalReason.trim()}'
          : body;

      await _showNotification(
        channelId: 'justification_channel_id',
        channelName: 'Justification Notifications',
        channelDescription:
            'Notifications for justification approvals and refusals',
        title: title,
        body: fullBody,
        notificationId: justificationId.hashCode % 100000,
        payload: justificationId,
      );

      debugPrint(
        'Justification notification sent to $studentName for $subjectName',
      );
    } catch (e) {
      debugPrint('Error sending justification notification: $e');
    }
  }

  /// Send exclusion status notification to a student.
  Future<void> sendExclusionNotification({
    required String studentName,
    required String subjectName,
    required String teacherName,
    required String exclusionId,
    required bool isApproved,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final title = isApproved ? 'Exclusion Approved' : 'Exclusion Rejected';
      final body = isApproved
          ? 'You have been excluded from $subjectName with $teacherName.'
          : 'The exclusion request for $subjectName with $teacherName was rejected.';

      await _showNotification(
        channelId: 'exclusion_channel_id',
        channelName: 'Exclusion Notifications',
        channelDescription: 'Notifications for subject exclusion decisions',
        title: title,
        body: body,
        notificationId: exclusionId.hashCode % 100000,
        payload: exclusionId,
      );

      debugPrint('Exclusion notification sent to $studentName for $subjectName');
    } catch (e) {
      debugPrint('Error sending exclusion notification: $e');
    }
  }

  /// Send batch notifications for multiple absent students
  Future<void> sendAbsenceNotificationBatch({
    required List<Map<String, String>> absentStudents,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Request permissions first
    await requestPermissions();

    for (final student in absentStudents) {
      final studentName = student['studentName'] ?? 'Student';
      final subjectName = student['subjectName'] ?? 'Subject';
      final teacherName = student['teacherName'] ?? 'Teacher';
      final absenceId = student['absenceId'] ?? '';

      await sendAbsenceNotification(
        studentName: studentName,
        subjectName: subjectName,
        teacherName: teacherName,
        absenceId: absenceId,
      );

      // Add small delay between notifications to avoid overwhelming
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(String absenceId) async {
    try {
      final int notificationId = absenceId.hashCode % 100000;
      await _flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
