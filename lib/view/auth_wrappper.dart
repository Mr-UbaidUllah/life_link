import 'package:blood_donation/view/HomeScreens/home_screen.dart';
import 'package:blood_donation/view/Profile_screen/personel_information.dart';
import 'package:blood_donation/view/auth%20_screens.dart/login_screen.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData) {
          // User not logged in
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }

            // Safely read user data
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

            if (userData == null) {
              return const LoginScreen();
            }

            final bool profileCompleted = userData['profileCompleted'] ?? false;

            // Decide screen based on profile completion
            if (profileCompleted) {
              return const MainScreen();
            } else {
              return const PersonelInformation();
            }
          },
        );
      },
    );
  }
}
