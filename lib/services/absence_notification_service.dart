import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ========================================
// Absence Notification Service
// Configures local reminders and absence
// alerts triggered by attendance events.
// ========================================

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

  /// Send a simple generic notification (title/message) optionally with payload
  Future<void> sendSimpleNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'general_channel_id',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        autoCancel: true,
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

      final int notificationId = (payload ?? DateTime.now().toIso8601String()).hashCode % 100000;

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        message,
        notificationDetails,
        payload: payload,
      );

      debugPrint('Simple notification sent: $title - $message');
    } catch (e) {
      debugPrint('Error sending simple notification: $e');
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
