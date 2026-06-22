import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/services/user_service.dart';
import 'package:blood_donation/utils/app_logger.dart';

/// Handles the current user's profile photo (upload + delete).
class StorageProvider extends BaseStateProvider {
  StorageProvider({
    StorageService? storageService,
    UserFirestoreService? userService,
  })  : _storageService = storageService ?? StorageService(),
        _userService = userService ?? UserFirestoreService();

  final StorageService _storageService;
  final UserFirestoreService _userService;

  UserModel? user;

  /// Human-readable reason for the last failed upload/delete, or null on success.
  String? error;

  Future<bool> uploadImage(String uid, File image) async {
    setLoading(true);
    error = null;
    try {
      final imageUrl = await _storageService.uploadImage(
        folder: FirebaseConstants.profileImagesFolder,
        id: uid,
        image: image,
      );
      await _userService.setProfileImage(uid, imageUrl);
      user = user?.copyWith(profileImage: imageUrl);
      return true;
    } on FirebaseException catch (e) {
      error = _friendlyError(e);
      AppLogger.e('uploadImage failed: ${e.code}', e);
      return false;
    } catch (e) {
      error = 'Could not upload your photo. Please try again.';
      AppLogger.e('uploadImage failed', e);
      return false;
    } finally {
      setLoading(false);
    }
  }

  String _friendlyError(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
      case 'permission-denied':
        return 'You don\'t have permission to upload images. '
            'Please contact support.';
      case 'unavailable':
      case 'network-request-failed':
      case 'retry-limit-exceeded':
        return 'No internet connection. Check your network and try again.';
      case 'canceled':
        return 'Upload canceled.';
      default:
        return 'Could not upload your photo. Please try again.';
    }
  }

  Future<bool> deleteImage(String uid) async {
    setLoading(true);
    try {
      final ok = await _storageService.deleteImage(
        folder: FirebaseConstants.profileImagesFolder,
        id: uid,
      );
      if (ok) await _userService.clearProfileImage(uid);
      return ok;
    } finally {
      setLoading(false);
    }
  }
}
