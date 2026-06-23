import 'dart:async';

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

  // Live set of request ids the user has hidden, sourced from the server-side
  // `dismissedRequests` subcollection. Feeds read this to filter.
  Set<String> _dismissedRequestIds = const {};
  Set<String> get dismissedRequestIds => _dismissedRequestIds;
  StreamSubscription<Set<String>>? _dismissedSub;

  /// Subscribes to the current user's hidden-request set. Idempotent: it only
  /// opens the Firestore listener once. `loadCurrentUser()` is called from
  /// nearly every screen's initState and every pull-to-refresh, so re-binding
  /// here would tear down and re-open the listener on each of those. On account
  /// switch, `clearUser()` cancels and nulls the sub, so the next load rebinds.
  void _bindDismissed() {
    if (_dismissedSub != null) return;
    _dismissedSub = _firestoreService.dismissedRequestIds().listen((ids) {
      _dismissedRequestIds = ids;
      notifyListeners();
    });
  }

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
        // Start the hidden-request listener now that we have a uid. The loading
        // flag is reset and notified once in `finally`.
        _bindDismissed();
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
    _dismissedSub?.cancel();
    _dismissedSub = null;
    _dismissedRequestIds = const {};
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissedSub?.cancel();
    super.dispose();
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestoreService.setProfileImage(uid, imageUrl);
      await loadCurrentUser();
    } catch (e) {
      _error = e.toString();
      AppLogger.e('updateProfileImage failed', e);
      notifyListeners();
    }
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

  /// Persists the donor opt-in. Returns true on success, false if the write
  /// failed (the optimistic flip is reverted) so callers can surface the error
  /// instead of falsely reporting success.
  Future<bool> toggleDonate(bool value) async {
    final previous = isWilling;
    isWilling = value;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.updateDonateStatus(value);

      // Re-fetch so the cached user reflects the new donate status.
      // (Previously the `false` branch nulled `_user`, wiping profile data.)
      _user = await _firestoreService.fetchCurrentUser();
      return true;
    } catch (e) {
      // Revert the optimistic flip so the switch matches the real state.
      isWilling = previous;
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the donor's on-call availability. Optimistic: updates the cached
  /// user(s) in place so the switch reacts instantly, reverting on failure.
  Future<void> setAvailability(bool value) async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final prevUser = _user;
    final prevPost = _postUser;

    if (_user != null) _user = _user!.copyWith(isAvailable: value);
    if (_postUser != null && _postUser!.uid == me) {
      _postUser = _postUser!.copyWith(isAvailable: value);
    }
    notifyListeners();

    try {
      await _firestoreService.setAvailability(value);
    } catch (e) {
      _user = prevUser;
      _postUser = prevPost;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Blocks another user and refreshes the cached profile so feeds filter
  /// their content immediately. Returns false (instead of throwing) if the
  /// write fails, so the caller can show an error rather than a false success.
  Future<bool> blockUser(String otherUid) async {
    try {
      await _firestoreService.blockUser(otherUid);
      await loadCurrentUser();
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.e('blockUser failed', e);
      return false;
    }
  }

  /// Hides [requestId] until [expireAt] (defaults to the request's natural
  /// lifetime). The live [dismissedRequestIds] stream reflects it instantly —
  /// no reload needed. Errors are swallowed (logged) since this is best-effort
  /// optimistic UI driven by the stream.
  Future<void> dismissRequest(String requestId, DateTime expireAt) async {
    try {
      await _firestoreService.dismissRequest(requestId, expireAt);
    } catch (e) {
      AppLogger.e('dismissRequest failed', e);
    }
  }

  /// Bulk-hides requests ("Clear feed"). [idToExpiry] maps each id to when its
  /// dismissal may be garbage-collected.
  Future<void> dismissAllRequests(Map<String, DateTime> idToExpiry) async {
    try {
      await _firestoreService.dismissRequests(idToExpiry);
    } catch (e) {
      AppLogger.e('dismissAllRequests failed', e);
    }
  }

  Stream<List<UserModel>> get donors {
    return _firestoreService.getDonors();
  }
}
