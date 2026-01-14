import 'package:blood_donation/Models/user_model.dart';
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
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'country': country,
      'city': city,
    });
  }

  Future<void> updateBasicInfo({
    required String uid,
    required String dateOfBirth,
    required String gender,
    required String wantToDonate,
    required String about,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'wantToDonate': wantToDonate,
      'about': about,
    });
  }

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
}
