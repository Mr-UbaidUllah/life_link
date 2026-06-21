import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodgroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get posts by a specific blood group.
  /// Mirrors BloodRequestService.getRequests: only surface requests that are
  /// still 'open' AND not expired, newest first — otherwise this screen would
  /// show already-fulfilled (closed) and stale requests that every other list
  /// hides, and let a user call/message someone whose need is over.
  Stream<List<BloodRequestModel>> getPostsByBloodGroup(String bloodGroup) {
    return _firestore
        .collection('Blood_request')
        .where('bloodGroup', isEqualTo: bloodGroup)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final list = snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.id, doc.data()))
              .where((req) => req.status == 'open' && req.expiryDate.isAfter(now))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
