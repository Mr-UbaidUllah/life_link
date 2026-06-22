import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:blood_donation/utils/app_logger.dart';

/// Single image-storage service for the whole app.
///
/// Replaces the four near-identical storage services (profile, ambulance,
/// organization, volunteer) that each hard-coded one folder. Callers pass the
/// folder (see [FirebaseConstants] `*ImagesFolder`) and the entity id.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Reference _ref(String folder, String id) =>
      _storage.ref().child('$folder/$id.jpg');

  /// Uploads [image] to `<folder>/<id>.jpg` and returns the download URL.
  Future<String> uploadImage({
    required String folder,
    required String id,
    required File image,
  }) async {
    final ref = _ref(folder, id);
    await ref.putFile(image);
    return ref.getDownloadURL();
  }

  /// Deletes `<folder>/<id>.jpg`. Returns true on success, false if it could
  /// not be removed (e.g. it never existed) — callers decide whether to care.
  Future<bool> deleteImage({
    required String folder,
    required String id,
  }) async {
    try {
      await _ref(folder, id).delete();
      return true;
    } catch (e) {
      AppLogger.e('deleteImage failed for $folder/$id', e);
      return false;
    }
  }
}
