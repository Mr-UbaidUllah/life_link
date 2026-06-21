import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BloodRequestService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(BloodRequestModel request) async {
    final data = request.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('Blood_request').add(data);
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': status,
    });
  }

  /// ✅ ACCEPT REQUEST: Set status to 'in_progress' and save current user UID
  Future<void> acceptRequest(String requestId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': 'in_progress',
      'acceptedByUserId': uid,
    });
  }

  /// ✅ CANCEL ACCEPTANCE: Revert status to 'open' and remove acceptedByUserId
  Future<void> cancelAcceptance(String requestId) async {
    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': 'open',
      'acceptedByUserId': FieldValue.delete(),
    });
  }

  /// ✅ COMPLETE REQUEST: Set status to 'closed'
  Future<void> completeRequest(String requestId) async {
    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': 'closed',
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('Blood_request').doc(requestId).delete();
  }

  Future<void> clearAllRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final collection = await _firestore
        .collection('Blood_request')
        .where('userId', isEqualTo: uid)
        .get();
    final batch = _firestore.batch();
    for (final doc in collection.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<BloodRequestModel>> getRequests() {
    return _firestore
        .collection('Blood_request')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs.map((doc) {
            return BloodRequestModel.fromMap(doc.id, doc.data());
          }).where((req) {
            // Only show 'open' requests that haven't expired yet
            final isOpen = req.status == 'open';
            final isNotExpired = req.expiryDate.isAfter(now);
            return isOpen && isNotExpired;
          }).toList();
        });
  }
}
