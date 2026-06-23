import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodgroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get posts by a specific blood group.
  /// Mirrors BloodRequestService.getRequests: only surface requests that are
  /// still 'open' AND not expired, newest first — otherwise this screen would
  /// show already-fulfilled (closed) and stale requests that every other list
  /// hides, and let a user call/message someone whose need is over.
  Stream<List<BloodRequestModel>> getPostsByBloodGroup(
    String bloodGroup, {
    int limit = 50,
  }) {
    // Filter by blood group AND open status server-side, newest first, capped.
    // Requires composite index:
    //   Blood_request (bloodGroup ASC, status ASC, createdAt DESC).
    // Expiry stays a client-side check (per-doc timestamp). Over-fetch then trim
    // so expired-but-still-`open` docs can't starve this list (see
    // BloodRequestService.getRequests for the rationale).
    return _firestore
        .collection('Blood_request')
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .limit(limit * _overFetchFactor)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          return snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.id, doc.data()))
              .where((req) => req.expiryDate.isAfter(now))
              .take(limit)
              .toList();
        });
  }

  static const int _overFetchFactor = 3;
}
