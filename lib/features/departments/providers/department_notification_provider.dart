import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/features/departments/models/department_notification_model.dart';
import 'package:test/features/departments/data/department_notification_service.dart';

class DepartmentNotificationProvider extends ChangeNotifier {
  DepartmentNotificationProvider({DepartmentNotificationService? service})
    : _service = service ?? DepartmentNotificationService();

  final DepartmentNotificationService _service;

  List<DepartmentNotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  List<DepartmentNotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize listeners for a department
  void initializeDepartmentNotifications(String departmentId) {
    if (_isInitialized) return;
    _isInitialized = true;

    print(
      '[DepartmentNotificationProvider] Initializing for department: $departmentId',
    );

    // Listen to notifications
    _service
        .watchNotificationsByDepartment(departmentId)
        .listen(
          (notifications) {
            print(
              '[DepartmentNotificationProvider] Received ${notifications.length} notifications',
            );
            _notifications = notifications;
            notifyListeners();
          },
          onError: (error) {
            print(
              '[DepartmentNotificationProvider] Error listening to notifications: $error',
            );
            _error = error.toString();
            notifyListeners();
          },
        );

    // Listen to unread count
    _service
        .watchUnreadNotificationCount(departmentId)
        .listen(
          (count) {
            print('[DepartmentNotificationProvider] Unread count: $count');
            _unreadCount = count;
            notifyListeners();
          },
          onError: (error) {
            print(
              '[DepartmentNotificationProvider] Error listening to unread count: $error',
            );
          },
        );
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      // Update local list
      _notifications = _notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      notifyListeners();
    } catch (e) {
      print('[DepartmentNotificationProvider] Error marking as read: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String departmentId) async {
    try {
      await _service.markAllAsRead(departmentId);
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      print('[DepartmentNotificationProvider] Error marking all as read: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get justification details
  Future<Map<String, dynamic>> getJustificationDetails(
    String justificationId,
  ) async {
    try {
      return await _service.getJustificationDetails(justificationId);
    } catch (e) {
      print('[DepartmentNotificationProvider] Error getting justification: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset provider (on logout)
  void reset() {
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }
}
