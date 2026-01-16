import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class VoluntterStorageService {
  Future<String> uploadorganizationImage(String uid, File image) async {
    final FirebaseStorage storage = FirebaseStorage.instance;
    // final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final ref = storage.ref().child('volunteer_images/$uid.jpg');

    await ref.putFile(image);

    return await ref.getDownloadURL();
  }
}
