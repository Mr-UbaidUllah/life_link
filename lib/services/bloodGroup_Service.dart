import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodgroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get posts by a specific blood group
  Stream<List<BloodRequestModel>> getPostsByBloodGroup(String bloodGroup) {
    return _firestore
        .collection('Blood_request')
        .where(
          'bloodGroup',
          isEqualTo: bloodGroup,
        ) //.where used for the Filtration
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
