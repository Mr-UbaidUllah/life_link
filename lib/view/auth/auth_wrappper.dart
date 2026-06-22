import 'package:blood_donation/theme/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/bottom_navigation.dart';
import 'package:blood_donation/view/profile/basic_information.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/view/profile/personal_information.dart';
import 'package:blood_donation/utils/setup_flow.dart';
import 'package:blood_donation/services/auth_service.dart';
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

  /// Re-fetch the profile after a transient failure (e.g. launched offline
  /// with no cached doc). Clearing [_uid] forces [_userDocFor] to build a
  /// fresh future on the next rebuild instead of returning the failed one.
  void _retry() {
    setState(() {
      _uid = null;
      _userDocFuture = null;
    });
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

            // HANDLE FIRESTORE ERROR — most commonly launching offline with no
            // cached profile doc. Offer a retry and a logout escape so the user
            // is never permanently locked out of the app.
            if (userSnapshot.hasError) {
              return _ProfileLoadError(onRetry: _retry);
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

/// Shown when the signed-in user's profile can't be loaded (typically an
/// offline launch with no cached document). Provides a retry and a logout
/// escape so the user is never stranded on a dead-end screen.
class _ProfileLoadError extends StatefulWidget {
  const _ProfileLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<_ProfileLoadError> createState() => _ProfileLoadErrorState();
}

class _ProfileLoadErrorState extends State<_ProfileLoadError> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await AuthService().logout();
    } catch (_) {
      // Sign-out is local; even if token cleanup fails the auth state stream
      // will route back to the login screen. Restore the button if it didn't.
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 56.r, color: AppColors.primary),
              SizedBox(height: 16.h),
              Text(
                'Couldn\'t load your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loggingOut ? null : widget.onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: const Text('Retry'),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: _loggingOut ? null : _logout,
                child: _loggingOut
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
