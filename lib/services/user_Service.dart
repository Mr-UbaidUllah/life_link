import 'package:blood_donation/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updatePersonalInfo({
    required String uid,
    required String name,
    required String phone,
    required String bloodGroup,
    required String country,
    required String city,
    String? about,
  }) async {
    // Use set+merge instead of update: if the profile doc is missing (e.g. a
    // signup whose Firestore write failed), update() would throw not-found and
    // the user could never complete setup.
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'country': country,
      'city': city,
      'about': about,
    }, SetOptions(merge: true));
  }

  Future<void> updateBasicInfo({
    required String uid,
    required String wantToDonate,
    required String about,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      // The whole app reads `isDonor` (donors query, profile, edit screen).
      // Map the onboarding "Yes"/"No" choice onto it so donors actually appear.
      'isDonor': wantToDonate.toLowerCase() == 'yes',
      'about': about,
      // Marks Step 2 as done so AuthWrapper can resume a returning user on the
      // first incomplete step instead of always starting at Step 1.
      'basicInfoCompleted': true,
    }, SetOptions(merge: true));
  }

  // fetch the current user details
  Future<UserModel?> fetchCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<UserModel?> fetchUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateDonateStatus(bool isDonor) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({'isDonor': isDonor});
  }

  Future<void> dismissRequest(String requestId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'dismissedRequests': FieldValue.arrayUnion([requestId]),
    });
  }

  Future<void> dismissAllRequests(List<String> requestIds) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).update({
      'dismissedRequests': FieldValue.arrayUnion(requestIds),
    });
  }

  Stream<List<UserModel>> getDonors() {
    return _firestore
        .collection('users')
        .where('isDonor', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('DONORS COUNT: ${snapshot.docs.length}');

          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  /// 🔹 Fetch ALL users
  Stream<List<UserModel>> fetchAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      debugPrint('USERS COUNT: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        debugPrint('USER DATA: ${doc.data()}');

        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
