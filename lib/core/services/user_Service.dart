import 'package:blood_donation/Models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    return UserModel.fromMap(doc.data()!);
  }
}
