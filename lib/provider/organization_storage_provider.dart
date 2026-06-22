import 'dart:io';

import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/services/organization_service.dart';
import 'package:blood_donation/utils/app_logger.dart';

class OrganizationStorageProvider extends BaseStateProvider {
  OrganizationStorageProvider({
    StorageService? storageService,
    OrganizationService? organizationService,
  })  : _storageService = storageService ?? StorageService(),
        _organizationService = organizationService ?? OrganizationService();

  final StorageService _storageService;
  final OrganizationService _organizationService;

  Future<bool> uploadImage(String id, File image) async {
    setLoading(true);
    try {
      final imageUrl = await _storageService.uploadImage(
        folder: FirebaseConstants.organizationImagesFolder,
        id: id,
        image: image,
      );
      await _organizationService.updateImage(id, imageUrl);
      return true;
    } catch (e) {
      AppLogger.e('Organization image upload failed', e);
      return false;
    } finally {
      setLoading(false);
    }
  }
}
