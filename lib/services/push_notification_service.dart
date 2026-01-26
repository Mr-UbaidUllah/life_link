import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'blood_requests',
    'Blood Requests',
    description: 'Urgent blood donation requests',
    importance: Importance.high,
  );

  // 🔹 CALL THIS AFTER LOGIN
  Future<void> initialize() async {
    print("🔔 Initializing notifications...");

    // 1️⃣ Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print("❌ Permission denied");
      return;
    }

    print("✅ Permission granted");

    // 2️⃣ Get FCM token
    String? token = await _messaging.getToken();
    print("✅ FCM Token: $token");

    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // 3️⃣ Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // 4️⃣ Setup local notifications
    await _setupLocalNotifications();

    // 5️⃣ Foreground notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6️⃣ When notification is tapped
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📲 Notification clicked");
    });

    // 7️⃣ App opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print("🚀 App opened from terminated state");
    }
  }

  // 🔹 SAVE TOKEN (FIXED)
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("❌ User not logged in");
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    print("✅ Token saved to Firestore");
  }

  // 🔹 LOCAL NOTIFICATION SETUP
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

    print("✅ Local notifications ready");
  }

  // 🔹 FOREGROUND HANDLER
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print("📬 Foreground notification");
      print(message.notification?.title);
      print(message.notification?.body);
    }

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

// 🔹 BACKGROUND / TERMINATED HANDLER
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📬 Background notification: ${message.notification?.title}");
}
