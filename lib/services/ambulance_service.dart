import 'package:blood_donation/core/base/base_firestore_service.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/ambulance_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmbulanceService extends BaseFirestoreService<AmbulanceModel> {
  AmbulanceService({super.firestore}) : super(FirebaseConstants.ambulance);

  @override
  AmbulanceModel fromMap(String id, Map<String, dynamic> map) =>
      AmbulanceModel.fromMap(id, map);

  @override
  Map<String, dynamic> toMap(AmbulanceModel item) => item.toMap();

  @override
  String idOf(AmbulanceModel item) => item.id;

  // ---- Convenience API (kept for existing call sites) ----
  // Stamps the creator so security rules can scope edits/deletes to the owner.
  Future<void> addAmbulance(AmbulanceModel ambulance) {
    final data = toMap(ambulance)
      ..['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
    return collection.doc(idOf(ambulance)).set(data);
  }

  Stream<List<AmbulanceModel>> getAmbulances({int? limit}) =>
      streamAll(limit: limit);

  Future<void> updateImageUrl(String id, String url) =>
      update(id, {'imageUrl': url});
}
