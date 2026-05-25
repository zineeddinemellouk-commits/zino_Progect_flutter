import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:test/services/absence_notification_service.dart';

// ========================================
// Push Notification Service
// Handles Firebase Cloud Messaging setup,
// token registration, and foreground alerts.
// ========================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
    '[PushNotificationService] Background message: ${message.messageId} ${message.notification?.title ?? ''}',
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    final currentToken = await _messaging.getToken();
    if (currentToken != null) {
      await _storeTokenForCurrentUser(currentToken);
    }

    _messaging.onTokenRefresh.listen((token) async {
      await _storeTokenForCurrentUser(token);
    });

    _initialized = true;
  }

  Future<void> registerCurrentUserToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;

    await _storeTokenForUser(user.uid, token.trim());
  }

  Future<void> _requestPermission() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] Permission request failed: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await AbsenceNotificationService().sendSimpleNotification(
      title: notification.title ?? 'Notification',
      message: notification.body ?? '',
      payload: message.messageId ?? message.data['notificationId']?.toString(),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint(
      '[PushNotificationService] Opened notification: ${message.messageId} ${message.notification?.title ?? ''}',
    );
  }

  Future<void> _storeTokenForCurrentUser(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _storeTokenForUser(user.uid, token);
  }

  Future<void> _storeTokenForUser(String uid, String token) async {
    final normalizedUid = uid.trim();
    final normalizedToken = token.trim();
    if (normalizedUid.isEmpty || normalizedToken.isEmpty) return;

    try {
      final batch = _firestore.batch();

      final userProfileRef = _firestore.collection('user_profiles').doc(normalizedUid);
      batch.set(userProfileRef, {
        'fcmToken': normalizedToken,
        'fcmTokens': FieldValue.arrayUnion([normalizedToken]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final profileSnap = await _firestore
          .collection('students')
          .where('authUid', isEqualTo: normalizedUid)
          .limit(10)
          .get();
      for (final doc in profileSnap.docs) {
        batch.set(doc.reference, {
          'fcmToken': normalizedToken,
          'fcmTokens': FieldValue.arrayUnion([normalizedToken]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[PushNotificationService] Failed to store token: $e');
    }
  }
}
