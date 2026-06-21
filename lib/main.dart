import 'package:blood_donation/core/providers/app_providers.dart';
import 'package:blood_donation/provider/theme_provider.dart';
import 'package:blood_donation/services/push_notification_service.dart';
import 'package:blood_donation/splash_screen.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/widgets/network_wrapper.dart'; // Import NetworkWrapper
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(' Background Message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  ///  Register background notification handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: AppProviders.providers,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (_, _) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Life Link',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          // Use the builder property to wrap all navigation routes with NetworkWrapper
          builder: (context, child) {
            return NetworkWrapper(child: child!);
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
