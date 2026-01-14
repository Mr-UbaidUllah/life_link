import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/bloodGroup_provider.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/provider/organization_storage_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/provider/volunteer_provider.dart';
import 'package:blood_donation/provider/volunteer_storagar_provider.dart';

import 'package:blood_donation/view/auth/auth_wrappper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // await Supabase.initialize(
  //   url: 'https://fjohvobuwontphqccgbo.supabase.co',
  //   anonKey:
  //       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqb2h2b2J1d29udHBocWNjZ2JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODgwMzIsImV4cCI6MjA4MjA2NDAzMn0.vaE6pNyg8dzU2zrxYKtMJUVWeEd0-dW_mSXjKnvbhNQ',
  // );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProviders()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => BloodrequestProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserPostsProvider()),
        ChangeNotifierProvider(create: (_) => BloodGroupRequestProvider()),
        ChangeNotifierProvider(create: (_) => OrganizationProvider()),
        ChangeNotifierProvider(create: (_) => OrganizationStorageProvider()),
        ChangeNotifierProvider(create: (_) => AmbulanceProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerProvider()),
        ChangeNotifierProvider(create: (_) => volunteerStorageProvider()),
      ],
      child: ScreenUtilInit(
        designSize: Size(375, 812),
        minTextAdapt: true,
        builder: (_, _) => MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
    );
  }
}
