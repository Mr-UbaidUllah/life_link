import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Writes user-submitted abuse reports to a `reports` collection for admin
/// review. Kept deliberately small — moderation tooling lives server-side.
class ReportService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> reportRequest({
    required String requestId,
    required String reportedUserId,
    required String reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('reports').add({
      'type': 'blood_request',
      'requestId': requestId,
      'reportedUserId': reportedUserId,
      'reportedBy': uid,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
