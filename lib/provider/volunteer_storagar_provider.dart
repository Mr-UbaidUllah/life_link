import 'dart:io';

import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/services/volunteer_service.dart';
import 'package:blood_donation/utils/app_logger.dart';

// ignore: camel_case_types
class volunteerStorageProvider extends BaseStateProvider {
  volunteerStorageProvider({
    StorageService? storageService,
    VolunteerService? volunteerService,
  })  : _storageService = storageService ?? StorageService(),
        _volunteerService = volunteerService ?? VolunteerService();

  final StorageService _storageService;
  final VolunteerService _volunteerService;

  Future<bool> uploadImage(String id, File image) async {
    setLoading(true);
    try {
      final imageUrl = await _storageService.uploadImage(
        folder: FirebaseConstants.volunteerImagesFolder,
        id: id,
        image: image,
      );
      await _volunteerService.updateImageUrl(id, imageUrl);
      return true;
    } catch (e) {
      AppLogger.e('Volunteer image upload failed', e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
