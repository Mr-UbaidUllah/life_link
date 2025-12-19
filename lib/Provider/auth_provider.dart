import 'package:blood_donation/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProviders with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;

  Future<UserCredential> signup(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      final credential = await _authService.signup(email, password);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Signup failed';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
