import 'package:firebase_auth/firebase_auth.dart';

/// Maps Firebase Auth error codes to short, user-friendly messages.
/// Codes are stable across Firebase versions; the raw messages are not, so we
/// never surface [FirebaseAuthException.message] for the known cases.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address looks invalid.';
    case 'user-disabled':
      return 'This account has been disabled. Please contact support.';
    case 'user-not-found':
      return 'No account found for that email. Please sign up first.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    // Newer Firebase (email-enumeration protection on) collapses
    // wrong-password / user-not-found into this single code.
    case 'invalid-credential':
      return 'Incorrect email or password. Please try again.';
    case 'email-already-in-use':
      return 'An account already exists for that email. Please log in.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is currently disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    default:
      return e.message ?? 'Authentication failed. Please try again.';
  }
}

/// Maps non-auth Firebase failures (Firestore/Storage) to friendly text.
String firebaseErrorMessage(FirebaseException e) {
  if (e.code == 'unavailable' || e.code == 'network-request-failed') {
    return 'No internet connection. Check your network and try again.';
  }
  return e.message ?? 'Something went wrong. Please try again.';
}
