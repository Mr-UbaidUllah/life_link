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

  /// ✅ ACCEPT REQUEST: atomically claim the request for the current user.
  /// Runs in a transaction so two donors can't both "win" the same request —
  /// the claim only succeeds if the request is still `open`. Throws if the
  /// request was already taken, completed, or deleted.
  Future<void> acceptRequest(String requestId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore.collection('Blood_request').doc(requestId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) {
        throw Exception('This request no longer exists.');
      }
      if (snap.data()?['status'] != 'open') {
        throw Exception('This request has already been accepted.');
      }
      txn.update(ref, {
        'status': 'in_progress',
        'acceptedByUserId': uid,
      });
    });
  }

  /// ✅ CANCEL ACCEPTANCE: revert to 'open', but only the donor who claimed it
  /// may cancel. Runs in a transaction to prevent one user undoing another's
  /// acceptance.
  Future<void> cancelAcceptance(String requestId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = _firestore.collection('Blood_request').doc(requestId);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;
      if (snap.data()?['acceptedByUserId'] != uid) {
        throw Exception('You can only cancel a request you accepted.');
      }
      txn.update(ref, {
        'status': 'open',
        'acceptedByUserId': FieldValue.delete(),
      });
    });
  }

  /// ✅ COMPLETE REQUEST: Set status to 'closed'
  Future<void> completeRequest(String requestId) async {
    await _firestore.collection('Blood_request').doc(requestId).update({
      'status': 'closed',
    });
  }

  /// Fetches a single request by id, or null if it no longer exists (e.g. the
  /// requester deleted it after the notification was sent).
  Future<BloodRequestModel?> getRequestById(String requestId) async {
    final doc =
        await _firestore.collection('Blood_request').doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return BloodRequestModel.fromMap(doc.id, doc.data()!);
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

  Stream<List<BloodRequestModel>> getRequests({int limit = 50}) {
    // Filter to open requests SERVER-SIDE (and cap the result) so the feed no
    // longer downloads the entire collection on every snapshot — closed/old
    // requests were filtered out client-side anyway. Expiry is still checked
    // client-side because it's a per-doc timestamp comparison.
    // Requires composite index: Blood_request (status ASC, createdAt DESC).
    //
    // Over-fetch then trim: expired-but-still-`open` docs (until the
    // closeExpiredRequests Cloud Function sweeps them) would otherwise consume
    // limit slots and shrink/empty the visible feed. Pulling a wider window and
    // trimming to `limit` after the expiry filter keeps the feed full.
    return _firestore
        .collection('Blood_request')
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

  // How much wider than `limit` to read so client-side expiry filtering can't
  // starve the feed. Belt-and-suspenders alongside the server-side sweep.
  static const int _overFetchFactor = 3;
}
