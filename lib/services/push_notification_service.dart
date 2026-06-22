import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blood_donation/utils/app_logger.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  // Add navigation key to navigate from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'blood_requests',
    'Blood Requests',
    description: 'Urgent blood donation requests',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    AppLogger.d("Initializing notifications...");

    // 1. Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      AppLogger.d("Notification permission denied");
      return;
    }

    AppLogger.d("Notification permission granted");

    // 2. Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // 3. Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 4. Setup local notifications
    await _setupLocalNotifications();

    // 5. Foreground notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. When notification is tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.d("Notification clicked");
    });

    // 7. App opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      AppLogger.d("App opened from terminated notification");
    }
  }

  // save token
  // NOTE: stored as a singular `fcmToken` string because the Cloud Function
  // (functions/index.js) reads `userData.fcmToken`. Migrating to a multi-device
  // `fcmTokens` array requires a coordinated function+client change — tracked
  // for the security/scale phase. Do not change the shape here in isolation.
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      AppLogger.d("Cannot save FCM token: user not logged in");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    AppLogger.d("FCM token saved");
  }

  //  LOCAL NOTIFICATION SETUP
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    // 🔥 CREATE ANDROID CHANNEL (VERY IMPORTANT)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    debugPrint("✅ Local notifications ready");
  }

  //  FOREGROUND HANDLER
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.d("Foreground notification: ${message.notification?.title}");
    _showLocalNotification(message);
  }

  // 🔹 SHOW NOTIFICATION
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description, 
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
    );
  }
}

//  BACKGROUND / TERMINATED HANDLER
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📬 Background notification: ${message.notification?.title}");
}
