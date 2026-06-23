import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/auth_service.dart';
import 'package:blood_donation/utils/auth_error_messages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProviders with ChangeNotifier {
  final AuthService _authService;
  bool isLoading = false;
  UserModel? user;

  AuthProviders({required AuthService authService}) : _authService = authService;

  Future<String?> signup(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.signup(email, password);
      return null; // Success
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

  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.login(email, password);
      user = await _authService.getCurrentUserData();
      return null; // Success
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

  /// Permanently deletes the account + the user's data. Reauthenticates with
  /// [password] first (Firebase requires a recent login to delete).
  Future<void> deleteAccount(String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.deleteAccount(password);
      user = null;
    } on FirebaseAuthException catch (e) {
      throw authErrorMessage(e);
    } on FirebaseException catch (e) {
      throw firebaseErrorMessage(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Could not delete your account. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
