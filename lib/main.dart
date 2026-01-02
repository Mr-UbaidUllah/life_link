import 'package:blood_donation/Provider/ambulance_provider.dart';
import 'package:blood_donation/Provider/auth_provider.dart';
import 'package:blood_donation/Provider/bloodGroup_provider.dart';
import 'package:blood_donation/Provider/bloodRequest_provider.dart';
import 'package:blood_donation/Provider/organization_provider.dart';
import 'package:blood_donation/Provider/organization_storage_provider.dart';
import 'package:blood_donation/Provider/storage_provider.dart';
import 'package:blood_donation/Provider/userPost_provider.dart';
import 'package:blood_donation/Provider/user_provider.dart';

import 'package:blood_donation/view/auth_wrappper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Supabase.initialize(
    url: 'https://fjohvobuwontphqccgbo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqb2h2b2J1d29udHBocWNjZ2JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0ODgwMzIsImV4cCI6MjA4MjA2NDAzMn0.vaE6pNyg8dzU2zrxYKtMJUVWeEd0-dW_mSXjKnvbhNQ',
  );
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
