import 'dart:io';
import 'dart:math';

import 'package:app_settings/app_settings.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();//This is used to SHOW notifications manually when the app is:
//Open (foreground)
//Or you want custom behavior
  void requestNotificationpermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print(' Permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print(' Provisional permission granted');
    } else {
      print('  Permission denied — opening settings');
      openNotificationSettings();
    }
  }

  // void initLocalNotifications(
  //   BuildContext context,
  //   RemoteMessage message,
  // ) async {
  //   var andriodInitializationSetting = AndroidInitializationSettings(
  //     '@mipmap/ic_launcher',
  //   );
  //   var initializationsetting = InitializationSettings(
  //     android: andriodInitializationSetting,
  //   );

  //   await flutterLocalNotificationsPlugin.initialize(
  //     initializationsetting,
  //     onDidReceiveNotificationResponse: (payload) {},
  //   );
  // }

  Future<String?> getDeviceToken() async {
    String? token = await messaging.getToken();
    return token;
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      if (Platform.isAndroid) {
        initLocalNotifications(context, message);
        showNotification(message);
      }
    });
  }

  void initLocalNotifications(
    BuildContext context,
    RemoteMessage message,
  ) async {
    var androidInitializationSetting = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var initializationSetting = InitializationSettings(
      android: androidInitializationSetting,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSetting,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'msj') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BloodrequestScreen()),
          );
        }
        // handleMessage(context, message);    
      },
    );
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'High importance notification',
      importance: Importance.max,
    );
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id.toString(),
          channel.name.toString(),
          channelDescription: 'Your channel description',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
        );
    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    Future.delayed(Duration.zero, () {
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: message.data['type'],
      );
    });
  }

  // Future<void> showNotification(RemoteMessage message) async {
  //   AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     Random.secure().nextInt(100000).toString(),
  //     'High importance notification',
  //     importance: Importance.max,
  //   );
  //   AndroidNotificationDetails androidNotificationDetails =
  //       AndroidNotificationDetails(
  //         channel.id.toString(),
  //         channel.name.toString(),
  //         channelDescription: 'Your channel description',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //         ticker: 'ticker',
  //       );
  //   NotificationDetails notificationDetails = NotificationDetails(
  //     android: androidNotificationDetails,
  //   );
  //   Future.delayed(Duration.zero, () {
  //     flutterLocalNotificationsPlugin.show(
  //       0,
  //       message.notification!.title.toString(),
  //       message.notification!.body.toString(),
  //       notificationDetails,
  //     );
  //   });
  // }

  void isDeviceTokenRefresh() {
    messaging.onTokenRefresh.listen((event) {
      event.toString();
    });
  }

  Future<void> setupInteractMessage(BuildContext context) async {
    // when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      handleMessage(context, initialMessage);
    }
    // when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });
  }

  void handleMessage(BuildContext context, RemoteMessage message) {
    if (message.data['type'] == 'msj') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BloodrequestScreen()),
      );
    }
  }
}

void openNotificationSettings() {
  AppSettings.openAppSettings(type: AppSettingsType.notification);
}
