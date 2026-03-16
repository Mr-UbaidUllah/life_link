import 'dart:io';

import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/services/amulance_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AmbulanceStorageProvider with ChangeNotifier {
  final _service = AmbulanceStorageService();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AmbulanceModel? ambulance;

  Future<bool> uploadImage(String uid, File image) async {
    isLoading = true;
    notifyListeners();
    try {
      final imageUrl = await _service.uploadorganizationImage(uid, image);
      await _firestore.collection('Ambulance').doc(uid).update({
        'imageUrl': imageUrl,
      });
      ambulance = ambulance?.copyWith(imageUrl: imageUrl);
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
