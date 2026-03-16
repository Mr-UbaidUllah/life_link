import 'package:blood_donation/models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationDatabaseService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<List<NotificationModel>> getNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> clearAll() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final collection = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .get();

    final batch = _firestore.batch();
    for (var doc in collection.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
