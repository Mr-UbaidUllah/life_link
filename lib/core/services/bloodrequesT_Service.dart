import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodrequestService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(BloodRequestModel request) async {
    await _firestore.collection('Blood_request').add(request.toMap());
  }

  Stream<List<BloodRequestModel>> getRequets() {
    return _firestore
        .collection('Blood_request')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BloodRequestModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }
}
