import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class  OrganizationstorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;


   Future<String> uploadorganizationImage(String uid, File image) async {
    final ref = _storage.ref().child('organization_images/$uid.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }
}