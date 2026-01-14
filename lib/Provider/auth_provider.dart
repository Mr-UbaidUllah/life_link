import 'package:blood_donation/Models/user_model.dart';
import 'package:blood_donation/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProviders with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  UserModel? user;

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

  Future<void> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.Login(email, password);
      user = await _authService.getCurrentUserData();
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    // user = null;
    notifyListeners();
  }
}
