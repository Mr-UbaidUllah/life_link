import 'package:blood_donation/core/base/base_firestore_service.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/organization_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganizationService extends BaseFirestoreService<OrganizationModel> {
  OrganizationService({super.firestore})
      : super(FirebaseConstants.organizations);

  @override
  OrganizationModel fromMap(String id, Map<String, dynamic> map) =>
      OrganizationModel.fromMap(id, map);

  @override
  Map<String, dynamic> toMap(OrganizationModel item) => item.toMap();

  @override
  String idOf(OrganizationModel item) => item.id;

  // ---- Convenience API (kept for existing call sites) ----
  // Stamps the creator so security rules can scope edits/deletes to the owner.
  Future<void> addOrganization(OrganizationModel org) {
    final data = toMap(org)
      ..['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
    return collection.doc(idOf(org)).set(data);
  }

  Stream<List<OrganizationModel>> getOrganizations({int? limit}) =>
      streamAll(limit: limit);

  Future<void> updateImage(String id, String url) =>
      update(id, {'image': url});
}
