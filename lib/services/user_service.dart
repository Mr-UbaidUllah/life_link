import 'package:blood_donation/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sets the user's profile image URL (set+merge so a partial doc still works).
  Future<void> setProfileImage(String uid, String imageUrl) {
    return _firestore.collection('users').doc(uid).set(
      {'profileImage': imageUrl},
      SetOptions(merge: true),
    );
  }

  /// Removes the user's profile image field.
  Future<void> clearProfileImage(String uid) {
    return _firestore.collection('users').doc(uid).update(
      {'profileImage': FieldValue.delete()},
    );
  }

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

  /// Saves the full health-screening details (Step 2 / "Update Health Details").
  Future<void> updateHealthInfo({
    required String uid,
    required bool isDonor,
    String? about,
    double? weightKg,
    DateTime? lastDonationDate,
    List<String> healthConditions = const [],
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'isDonor': isDonor,
      'about': about,
      'weightKg': weightKg,
      'lastDonationDate': lastDonationDate == null
          ? null
          : Timestamp.fromDate(lastDonationDate),
      'healthConditions': healthConditions,
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .set({'isDonor': isDonor}, SetOptions(merge: true));
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
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.id, doc.data());
          }).toList();
        });
  }

  /// Fetch ALL users
  Stream<List<UserModel>> fetchAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
