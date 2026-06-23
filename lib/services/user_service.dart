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

  // ---- Dismissed (hidden) requests ----
  //
  // Stored server-side as one doc per dismissal in
  // `users/{uid}/dismissedRequests/{requestId}`. Each doc carries an `expireAt`
  // timestamp so a Firestore TTL policy auto-deletes it once the underlying
  // request is gone — the list can never grow unbounded and needs no manual
  // pruning. (Enable TTL on the `expireAt` field for the `dismissedRequests`
  // collection group; see firestore.rules / project README.)

  CollectionReference<Map<String, dynamic>> _dismissedCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('dismissedRequests');

  /// Hides a single request for the current user until [expireAt].
  Future<void> dismissRequest(String requestId, DateTime expireAt) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _dismissedCol(uid).doc(requestId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'expireAt': Timestamp.fromDate(expireAt),
    });
  }

  /// Hides many requests at once (the "Clear feed" action). [idToExpiry] maps
  /// each request id to the moment its dismissal may be garbage-collected.
  Future<void> dismissRequests(Map<String, DateTime> idToExpiry) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || idToExpiry.isEmpty) return;

    final batch = _firestore.batch();
    idToExpiry.forEach((requestId, expireAt) {
      batch.set(_dismissedCol(uid).doc(requestId), {
        'createdAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expireAt),
      });
    });
    await batch.commit();
  }

  /// Live set of request ids the current user has hidden. Firestore's offline
  /// latency compensation means a just-written dismissal appears here
  /// immediately, so the feed updates without any local optimistic bookkeeping.
  Stream<Set<String>> dismissedRequestIds() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const <String>{});

    return _dismissedCol(uid).snapshots().map(
          (snap) => snap.docs.map((d) => d.id).toSet(),
        );
  }

  /// Sets the donor's "available to donate now" status.
  Future<void> setAvailability(bool isAvailable) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .set({'isAvailable': isAvailable}, SetOptions(merge: true));
  }

  /// Blocks [otherUid] for the current user — their requests are hidden and
  /// contact is disabled. Idempotent via arrayUnion.
  Future<void> blockUser(String otherUid) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == otherUid) return;

    await _firestore.collection('users').doc(uid).set({
      'blockedUsers': FieldValue.arrayUnion([otherUid]),
    }, SetOptions(merge: true));
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
}
