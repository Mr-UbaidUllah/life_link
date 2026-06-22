import 'dart:io';

import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/services/ambulance_service.dart';
import 'package:blood_donation/utils/app_logger.dart';

class AmbulanceStorageProvider extends BaseStateProvider {
  AmbulanceStorageProvider({
    StorageService? storageService,
    AmbulanceService? ambulanceService,
  })  : _storageService = storageService ?? StorageService(),
        _ambulanceService = ambulanceService ?? AmbulanceService();

  final StorageService _storageService;
  final AmbulanceService _ambulanceService;

  Future<bool> uploadImage(String id, File image) async {
    setLoading(true);
    try {
      final imageUrl = await _storageService.uploadImage(
        folder: FirebaseConstants.ambulanceImagesFolder,
        id: id,
        image: image,
      );
      await _ambulanceService.updateImageUrl(id, imageUrl);
      return true;
    } catch (e) {
      AppLogger.e('Ambulance image upload failed', e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
