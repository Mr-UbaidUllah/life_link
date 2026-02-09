import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/user_Service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final UserFirestoreService _firestoreService = UserFirestoreService();

  bool _isLoading = false;
  bool isWilling = false;
  final List<UserModel> _users = [];

  bool get isLoading => _isLoading;
  UserModel? _user;
  UserModel? _postUser;
  UserModel? get postUser => _postUser;
  String? _error;
  String? get error => _error;
  UserModel? get user => _user;
  List<UserModel> get users => _users;

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
      if (user != null) {
        isWilling = user!.isDonor;
        _isLoading = false;
        notifyListeners();
      }
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

  Future<void> updateProfileImage(String imageUrl) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImage': imageUrl,
    });

    await loadCurrentUser();
  }

  /// Load user by id (used in PostDetailsScreen)
  Future<void> loadUserById(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _postUser = await _firestoreService.fetchUserById(uid);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();  
    }
  }

  Future<void> toggleDonate(bool value) async {
    isWilling = value;
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    await _firestoreService.updateDonateStatus(value);

    if (value) {
      _user = await _firestoreService.fetchCurrentUser();
    } else {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Stream<List<UserModel>> get donors {
    return _firestoreService.getDonors();
  }

  Stream<List<UserModel>> get allUsers {
    print('get function${_firestoreService.fetchAllUsers()}');
    return _firestoreService.fetchAllUsers();
  }
}
