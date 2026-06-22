import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/user_service.dart';
import 'package:blood_donation/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({UserFirestoreService? service})
      : _firestoreService = service ?? UserFirestoreService();

  final UserFirestoreService _firestoreService;

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
    String? about,
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

  Future<bool> updateBasicInfo({
    required String uid,
    required String wantToDonate,
    required String about,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateBasicInfo(
        uid: uid,
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

  /// Saves the full health-screening form (weight, last donation, conditions).
  Future<bool> updateHealthInfo({
    required String uid,
    required bool isDonor,
    String? about,
    double? weightKg,
    DateTime? lastDonationDate,
    List<String> healthConditions = const [],
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestoreService.updateHealthInfo(
        uid: uid,
        isDonor: isDonor,
        about: about,
        weightKg: weightKg,
        lastDonationDate: lastDonationDate,
        healthConditions: healthConditions,
      );
      isWilling = isDonor;
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.e('updateHealthInfo failed', e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      AppLogger.e('Error loading user', e);
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestoreService.setProfileImage(uid, imageUrl);
    await loadCurrentUser();
  }

  /// Load user by id (used in PostDetailsScreen)
  Future<void> loadUserById(String uid) async {
    try {
      _isLoading = true;
      // Clear the previous post's user immediately. _postUser is a single
      // shared slot; without this it would keep showing the last post's owner
      // (and worse, target chat/avatar at them) until this fetch resolves — or
      // forever if the fetch throws.
      _postUser = null;
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
    final previous = isWilling;
    isWilling = value;
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.updateDonateStatus(value);

      // Re-fetch so the cached user reflects the new donate status.
      // (Previously the `false` branch nulled `_user`, wiping profile data.)
      _user = await _firestoreService.fetchCurrentUser();
    } catch (e) {
      // Revert the optimistic flip so the switch matches the real state.
      isWilling = previous;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> dismissRequest(String requestId) async {
    await _firestoreService.dismissRequest(requestId);
    await loadCurrentUser();
  }

  Future<void> dismissAllRequests(List<String> requestIds) async {
    _isLoading = true;
    notifyListeners();
    await _firestoreService.dismissAllRequests(requestIds);
    await loadCurrentUser();
    _isLoading = false;
    notifyListeners();
  }

  Stream<List<UserModel>> get donors {
    return _firestoreService.getDonors();
  }

  Stream<List<UserModel>> get allUsers {
    return _firestoreService.fetchAllUsers();
  }
}
