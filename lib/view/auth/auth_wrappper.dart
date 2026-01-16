import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/view/profile/personel_information.dart';
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

            // 🔴 HANDLE FIRESTORE ERROR
            if (userSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Something went wrong. Please restart app.'),
                ),
              );
            }

            // 🔹 Document not found
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const PersonelInformation();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>?;

            if (data == null) {
              return const PersonelInformation();
            }

            final bool profileCompleted = data['profileCompleted'] == true;

            // 🔹 Navigation decision
            return profileCompleted
                ? const MainScreen()
                : const PersonelInformation();
          },
        );
      },
    );
  }
}
