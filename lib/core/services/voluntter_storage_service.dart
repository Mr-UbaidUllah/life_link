import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VoluntterStorageService {
  Future<String> uploadorganizationImage(String uid, File image) async {
    final FirebaseStorage _storage = FirebaseStorage.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final ref = _storage.ref().child('volunteer_images/$uid.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }
}
