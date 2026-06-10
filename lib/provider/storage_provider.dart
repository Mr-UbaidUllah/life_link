import 'dart:io';

import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/Storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StorageProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  UserModel? user;
  bool isLoading = false;

  /// Human-readable reason for the last failed upload/delete, or null on success.
  String? error;

  Future<bool> uploadImage(String uid, File image) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final imageUrl = await _storageService.uploadProfileImage(uid, image);
      // set+merge (not update) so a missing/partial profile doc still succeeds.
      await _firestore.collection('users').doc(uid).set({
        'profileImage': imageUrl,
      }, SetOptions(merge: true));
      user = user?.copyWith(profileImage: imageUrl);
      return true;
    } on FirebaseException catch (e) {
      error = _friendlyError(e);
      debugPrint('uploadImage failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      error = 'Could not upload your photo. Please try again.';
      debugPrint('uploadImage failed: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
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
    try {
      isLoading = true;
      notifyListeners();

      return await _storageService.deleteProfileimage(uid);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
