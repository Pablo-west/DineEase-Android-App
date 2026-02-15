import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/home/user_notices_page.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;
    _navigatorKey = navigatorKey;

    if (!_isSupportedPlatform) return;

    try {
      if (Platform.isIOS || Platform.isMacOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } on MissingPluginException catch (e) {
      debugPrint('FCM requestPermission unavailable: $e');
      return;
    }

    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedFromNotification);
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleOpenedFromNotification(initialMessage);
      }
    } on MissingPluginException catch (e) {
      debugPrint('FCM open handlers unavailable: $e');
      return;
    }

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _saveToken(user.uid, token);
        }
      } on MissingPluginException catch (e) {
        debugPrint('FCM getToken unavailable: $e');
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _saveToken(user.uid, token);
    });
  }

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  static Future<void> _saveToken(String userId, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .doc(token)
        .set({
      'token': token,
      'platform': Platform.operatingSystem,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _handleOpenedFromNotification(RemoteMessage message) {
    final route = message.data['route']?.toString();
    if (route != 'notifications') return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final navigator = _navigatorKey?.currentState;
    if (userId == null || navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => UserNoticesPage(userId: userId),
      ),
    );
  }
}
