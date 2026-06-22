import 'package:blood_donation/core/base/base_firestore_service.dart';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/volunteer_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VolunteerService extends BaseFirestoreService<VolunteerModel> {
  VolunteerService({super.firestore}) : super(FirebaseConstants.volunteer);

  @override
  VolunteerModel fromMap(String id, Map<String, dynamic> map) =>
      VolunteerModel.fromMap(id, map);

  @override
  Map<String, dynamic> toMap(VolunteerModel item) => item.toMap();

  @override
  String idOf(VolunteerModel item) => item.id;

  // ---- Convenience API (kept for existing call sites) ----
  // Stamps the creator so security rules can scope edits/deletes to the owner.
  Future<void> addVolunteer(VolunteerModel volunteer) {
    final data = toMap(volunteer)
      ..['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
    return collection.doc(idOf(volunteer)).set(data);
  }

  Stream<List<VolunteerModel>> getVolunteers({int? limit}) =>
      streamAll(limit: limit);

  Future<void> updateImageUrl(String id, String url) =>
      update(id, {'imageUrl': url});
}
