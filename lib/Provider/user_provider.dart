import 'package:blood_donation/Models/user_model.dart';
import 'package:blood_donation/core/services/user_Service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final UserFirestoreService _firestoreService = UserFirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  UserModel? _user;

  String? _error;
  String? get error => _error;
  UserModel? get user => _user;

  /// Update personal information
  Future<bool> updatePersonalInfo({
    required String uid,
    required String name,
    required String phone,
    required String bloodGroup,
    required String country,
    required String city,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.updatePersonalInfo(
        uid: uid,
        name: name,
        phone: phone,
        bloodGroup: bloodGroup,
        country: country,
        city: city,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBasicInfo({
    required String uid,
    required String dateOfBirth,
    required String gender,
    required String wantToDonate,
    required String about,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateBasicInfo(
        uid: uid,
        dateOfBirth: dateOfBirth,
        gender: gender,
        wantToDonate: wantToDonate,
        about: about,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await _firestoreService.fetchCurrentUser();
    } catch (e) {
      debugPrint('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
