import 'dart:io';

import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/services/voluntter_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class volunteerStorageProvider with ChangeNotifier {
  final _service = VoluntterStorageService();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  VolunteerModel? volunteer;

  Future<bool> uploadImage(String uid, File image) async {
    isLoading = true;
    notifyListeners();
    try {
      final imageUrl = await _service.uploadorganizationImage(uid, image);
      await _firestore.collection('Volunteer').doc(uid).update({
        'imageUrl': imageUrl,
      });
      volunteer = volunteer?.copyWith(imageUrl: imageUrl);
      return true;
    } catch (e) {
      debugPrint(e.toString());
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}