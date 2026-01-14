import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BloodRequestModel>> getUserPosts(String userId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('Blood_request')
        .where('userId', isEqualTo: userId) // only current user's posts
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BloodRequestModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
