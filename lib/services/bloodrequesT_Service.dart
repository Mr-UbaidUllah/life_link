import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodrequestService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(BloodRequestModel request) async {
    await _firestore.collection('Blood_request').add(request.toMap());
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': status,
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('Blood_request').doc(requestId).delete();
  }

  Future<void> clearAllRequests() async {
    final collection = await _firestore.collection('Blood_request').get();
    final batch = _firestore.batch();
    for (final doc in collection.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<BloodRequestModel>> getRequets() {
    // We remove the server-side 'where' filter for 'status' temporarily 
    // to ensure existing documents (without the status field) are still visible.
    // We'll filter 'closed' requests in the mapping logic instead.
    return _firestore
        .collection('Blood_request')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.id, doc.data()))
              .where((req) => req.status != 'closed') // Filter out closed ones here
              .toList();
        });
  }
}
