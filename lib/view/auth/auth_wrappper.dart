import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/view/profile/basic_information.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/view/profile/personel_information.dart';
import 'package:blood_donation/utils/setup_flow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  /// Maps the first incomplete setup step to its screen for a returning user
  /// whose profile isn't finished yet. The decision logic lives in
  /// [firstIncompleteStep] so it can be unit-tested independently.
  Widget _resumeStep(Map<String, dynamic> data) {
    switch (firstIncompleteStep(data)) {
      case SetupStep.personalInfo:
        return const PersonelInformation();
      case SetupStep.basicInfo:
        return const BasicInformation();
      case SetupStep.photo:
        return const ImageScreen();
      case SetupStep.completed:
        return const MainScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 🔹 Loading auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔹 Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
          builder: (context, userSnapshot) {
            // 🔹 Loading Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // HANDLE FIRESTORE ERROR
            if (userSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Something went wrong. Please restart app.'),
                ),
              );
            }

            // Document not found
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const PersonelInformation();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const PersonelInformation();
            }

            // 🔹 Whole setup finished → straight to the app.
            if (data['profileCompleted'] == true) {
              return const MainScreen();
            }

            // 🔹 Otherwise resume on the FIRST incomplete step instead of
            // always restarting at Step 1.
            return _resumeStep(data);
          },
        );
      },
    );
  }
}
