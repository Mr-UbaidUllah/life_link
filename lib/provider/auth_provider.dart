import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/auth_service.dart';
import 'package:blood_donation/utils/auth_error_messages.dart';
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
      throw authErrorMessage(e);
    } on FirebaseException catch (e) {
      // Firestore / Storage failures (e.g. no network while saving the
      // profile document immediately after the account is created).
      throw firebaseErrorMessage(e);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
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
      throw authErrorMessage(e);
    } on FirebaseException catch (e) {
      throw firebaseErrorMessage(e);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    notifyListeners();
  }
}
