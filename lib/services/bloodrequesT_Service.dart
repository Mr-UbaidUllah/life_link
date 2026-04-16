import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(BloodRequestModel request) async {
    // Professional Fix: Use FieldValue.serverTimestamp() for createdAt 
    // to ensure consistency across all user devices.
    final data = request.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('Blood_request').add(data);
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

  /// PROFESSIONAL FIX: 
  /// We filter 'expiryDate' and 'status' on the client side within the stream.
  /// This avoids the "disappearing" issue caused by missing Firestore Composite Indexes
  /// and ensures the list is always up-to-date with the device's current time.
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
