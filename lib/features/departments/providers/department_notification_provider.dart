import 'package:flutter/foundation.dart';

/// Model for department notification
class DepartmentNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'info', 'warning', 'error', 'success'
  bool isRead;

  DepartmentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = 'info',
    this.isRead = false,
  });
}

/// Provider for managing department notifications
/// Handles notification management, filtering, and state
class DepartmentNotificationProvider extends ChangeNotifier {
  final List<DepartmentNotification> _notifications = [];

  // ── Getters ────────────────────────────────────────────────────
  List<DepartmentNotification> get notifications => _notifications;

  List<DepartmentNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  // ── Notification Management ────────────────────────────────────
  /// Add a new notification
  void addNotification({
    required String title,
    required String message,
    String type = 'info',
  }) {
    final notification = DepartmentNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
    );
    _notifications.insert(0, notification); // Newest first
    notifyListeners();
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    notifyListeners();
  }

  /// Remove a notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Clear old notifications (older than specified days)
  void clearOldNotifications({int daysOld = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
    notifyListeners();
  }

  /// Get notifications by type
  List<DepartmentNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Refresh notifications (for future use with real backend)
  Future<void> refreshNotifications() async {
    notifyListeners();
  }
}
