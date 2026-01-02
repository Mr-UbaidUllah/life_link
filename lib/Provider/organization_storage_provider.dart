import 'dart:io';

import 'package:blood_donation/Models/organization_model.dart';
import 'package:blood_donation/core/services/organizationStorage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrganizationStorageProvider with ChangeNotifier {
  final _service = OrganizationstorageService();
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  OrganizationModel? organization;

  Future<bool> uploadImage(String uid, File image) async {
    isLoading = true;
    notifyListeners();
    try {
      final imageUrl = await _service.uploadorganizationImage(uid, image);
      await _firestore.collection('organizations').doc(uid).update({
        'image': imageUrl,
      });
      organization = organization?.copyWith(image: imageUrl);
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
