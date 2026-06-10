import 'package:blood_donation/utils/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authErrorMessage — login/signup failure scenarios', () {
    String msg(String code, [String? message]) =>
        authErrorMessage(FirebaseAuthException(code: code, message: message));

    test('wrong password', () {
      expect(msg('wrong-password'), 'Incorrect password. Please try again.');
    });

    test('email not registered (user-not-found)', () {
      expect(msg('user-not-found'),
          'No account found for that email. Please sign up first.');
    });

    test('invalid-credential (new Firebase collapses wrong-pass/no-user)', () {
      expect(msg('invalid-credential'),
          'Incorrect email or password. Please try again.');
    });

    test('duplicate email on signup', () {
      expect(msg('email-already-in-use'),
          'An account already exists for that email. Please log in.');
    });

    test('no wifi / network down', () {
      expect(msg('network-request-failed'),
          'No internet connection. Check your network and try again.');
    });

    test('invalid email format', () {
      expect(msg('invalid-email'), 'That email address looks invalid.');
    });

    test('weak password', () {
      expect(msg('weak-password'),
          'Password is too weak. Use at least 6 characters.');
    });

    test('too many attempts', () {
      expect(msg('too-many-requests'),
          'Too many attempts. Please wait a moment and try again.');
    });

    test('disabled account', () {
      expect(msg('user-disabled'),
          'This account has been disabled. Please contact support.');
    });

    test('unknown code falls back to provided message', () {
      expect(msg('some-future-code', 'Raw detail'), 'Raw detail');
    });

    test('unknown code with no message falls back to generic', () {
      expect(
          msg('some-future-code'), 'Authentication failed. Please try again.');
    });

    test('never leaks raw Firebase wording for known codes', () {
      // Even if Firebase supplies an ugly message, the known code wins.
      expect(
        authErrorMessage(FirebaseAuthException(
          code: 'wrong-password',
          message: 'The supplied auth credential is incorrect, malformed...',
        )),
        'Incorrect password. Please try again.',
      );
    });
  });

  group('firebaseErrorMessage — Firestore/Storage failures', () {
    test('unavailable → network message', () {
      expect(
        firebaseErrorMessage(FirebaseException(plugin: 'firestore', code: 'unavailable')),
        'No internet connection. Check your network and try again.',
      );
    });

    test('network-request-failed → network message', () {
      expect(
        firebaseErrorMessage(
            FirebaseException(plugin: 'firestore', code: 'network-request-failed')),
        'No internet connection. Check your network and try again.',
      );
    });

    test('other code falls back to message', () {
      expect(
        firebaseErrorMessage(
            FirebaseException(plugin: 'firestore', code: 'aborted', message: 'Aborted')),
        'Aborted',
      );
    });
  });
}
