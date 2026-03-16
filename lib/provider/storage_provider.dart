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

  Future<bool> uploadImage(String uid, File image) async {
    try {
      isLoading = true;
      notifyListeners();

      final imageUrl = await _storageService.uploadProfileImage(uid, image);
      await _firestore.collection('users').doc(uid).update({
        'profileImage': imageUrl,
      });
      user = user?.copyWith(profileImage: imageUrl);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
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
