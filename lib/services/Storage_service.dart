import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadProfileImage(String uid, File image) async {
    final ref = _storage.ref().child('profile_images/$uid.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }

  Future<bool> deleteProfileimage(String uid) async {
    try {
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.delete();

      await _firestore.collection('users').doc(uid).update({
        'profileImage': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      debugPrint('Delete image error: $e');
      return false;
    }
  }
}
