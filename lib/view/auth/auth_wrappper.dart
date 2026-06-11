import 'package:blood_donation/theme/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/view/profile/basic_information.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/view/profile/personel_information.dart';
import 'package:blood_donation/utils/setup_flow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  // Profile document prefetched by the splash screen while its animation
  // plays, so arriving here doesn't stall on a network round trip.
  static Future<DocumentSnapshot<Map<String, dynamic>>>? _warmDoc;
  static String? _warmUid;

  /// Start fetching [uid]'s profile ahead of time (called from the splash).
  static void warmUp(String uid) {
    _warmUid = uid;
    _warmDoc = FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  /// Hand over the prefetched document once, then clear it so a later
  /// login never routes off stale data.
  static Future<DocumentSnapshot<Map<String, dynamic>>>? _takeWarmDoc(String uid) {
    final doc = _warmUid == uid ? _warmDoc : null;
    _warmDoc = null;
    _warmUid = null;
    return doc;
  }

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _uid;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _userDocFuture;

  /// One fetch per signed-in user — never re-created on rebuilds.
  Future<DocumentSnapshot<Map<String, dynamic>>> _userDocFor(String uid) {
    if (_uid != uid || _userDocFuture == null) {
      _uid = uid;
      _userDocFuture = AuthWrapper._takeWarmDoc(uid) ??
          FirebaseFirestore.instance.collection('users').doc(uid).get();
    }
    return _userDocFuture!;
  }

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
          return const _BrandedLoading();
        }

        // 🔹 Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: _userDocFor(uid),
          builder: (context, userSnapshot) {
            // 🔹 Loading Firestore
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const _BrandedLoading();
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

            final data = userSnapshot.data!.data();

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

/// Loading screen that matches the splash branding, so any residual wait
/// reads as a seamless continuation instead of a white flash.
class _BrandedLoading extends StatelessWidget {
  const _BrandedLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryDeep,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 30.r,
            height: 30.r,
            child: CircularProgressIndicator(
              color: Colors.white.withValues(alpha: 0.7),
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }
}
