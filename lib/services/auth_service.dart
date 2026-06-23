import 'dart:developer';
import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveFcmToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      // Write the SAME field name the rest of the system reads: the Cloud
      // Function (functions/index.js), NotificationService and ChatService all
      // read the singular string `fcmToken`. Writing an `fcmTokens` array here
      // meant a freshly-signed-up user had no readable token until an app
      // restart, so they never received blood-request notifications.
      await _firestore.collection(FirebaseConstants.users).doc(uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      log("FCM Token saved for user", name: 'AuthService');
    } catch (e, stackTrace) {
      log(
        "Error saving FCM token",
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<UserCredential> signup(String email, String password) async {
    // Create user in Firebase Auth;
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user model
    UserModel userModel = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      createdAt: DateTime.now(),
      profileCompleted: false,
    );

    try {
      // Save to Firestore
      await _firestore
          .collection(FirebaseConstants.users)
          .doc(userModel.uid)
          .set(userModel.toMap());
    } catch (e) {
      // The Auth account was created but the profile document couldn't be
      // persisted (e.g. network dropped mid-signup). Roll back the orphaned
      // account so the email is free to retry — otherwise the user is stuck
      // with "email-already-in-use" and no profile doc.
      try {
        await userCredential.user?.delete();
      } catch (_) {
        // Best-effort rollback; surface the original failure regardless.
      }
      rethrow;
    }

    // Non-fatal: a missing FCM token must not block signup.
    await _saveFcmToken(userModel.uid);

    return userCredential;
  }

  Future<void> login(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // SAVE / UPDATE FCM TOKEN AFTER LOGIN
    await _saveFcmToken(userCredential.user!.uid);
  }

  Future<void> _clearFcmToken(String uid) async {
    try {
      // Drop this device's token from the signed-out user's doc so a second
      // account on the same device never receives the previous user's pushes.
      // Also delete the registration so a stale token isn't re-read elsewhere.
      await _firestore.collection(FirebaseConstants.users).doc(uid).set({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.delete(),
      }, SetOptions(merge: true));
      await FirebaseMessaging.instance.deleteToken();
      log("FCM Token cleared for user", name: 'AuthService');
    } catch (e, stackTrace) {
      log(
        "Error clearing FCM token",
        name: 'AuthService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logout() async {
    // Capture the uid before signOut() nulls currentUser. Clearing the token
    // is best-effort — it must never block the user from logging out.
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _clearFcmToken(uid);
    }
    await _auth.signOut();
  }

  /// Permanently deletes the signed-in user's account and their personal data.
  ///
  /// Required for Play Store / App Store compliance (in-app account deletion).
  /// Firebase requires a *recent* login to delete an account, so the caller
  /// must supply the current password to reauthenticate first.
  ///
  /// Order matters: reauthenticate → wipe Firestore data the user owns (rules
  /// only permit deleting your own documents) → delete the Auth account last,
  /// because once the Auth user is gone the security rules would reject the
  /// data writes.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'You are not signed in.';
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw 'This account type cannot be deleted from the app.';
    }

    // 1. Reauthenticate (clears "requires-recent-login").
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    // 2. Best-effort clean-up of the user's own data.
    await _clearFcmToken(uid);
    await _deleteUserData(uid);

    // 3. Delete the authentication account itself.
    await user.delete();
  }

  /// Removes the Firestore data a user owns, then finally their profile
  /// document. Covers: blood requests, notifications subcollection,
  /// dismissedRequests subcollection, the ambulance / organization / volunteer
  /// listings they created (`createdBy == uid`), and every chat they're a
  /// participant of (including each chat's messages subcollection). Deletes are
  /// chunked to stay within Firestore's 500-write batch limit.
  Future<void> _deleteUserData(String uid) async {
    final refs = <DocumentReference>[];

    // Blood requests the user posted.
    final requests = await _firestore
        .collection(FirebaseConstants.bloodRequests)
        .where('userId', isEqualTo: uid)
        .get();
    refs.addAll(requests.docs.map((d) => d.reference));

    // Notifications + dismissed-request markers under the user's own doc.
    final notifications = await _firestore
        .collection(FirebaseConstants.users)
        .doc(uid)
        .collection(FirebaseConstants.notifications)
        .get();
    refs.addAll(notifications.docs.map((d) => d.reference));

    final dismissed = await _firestore
        .collection(FirebaseConstants.users)
        .doc(uid)
        .collection('dismissedRequests')
        .get();
    refs.addAll(dismissed.docs.map((d) => d.reference));

    // Listings this user created (each stamps `createdBy`).
    for (final collection in [
      FirebaseConstants.ambulance,
      FirebaseConstants.organizations,
      FirebaseConstants.volunteer,
    ]) {
      final owned = await _firestore
          .collection(collection)
          .where('createdBy', isEqualTo: uid)
          .get();
      refs.addAll(owned.docs.map((d) => d.reference));
    }

    // Chats the user is a participant of, plus each chat's messages. Deleting a
    // shared chat is intentional — once one side is gone the thread is dead.
    final chats = await _firestore
        .collection(FirebaseConstants.chats)
        .where('users', arrayContains: uid)
        .get();
    for (final chat in chats.docs) {
      final messages =
          await chat.reference.collection(FirebaseConstants.messages).get();
      refs.addAll(messages.docs.map((d) => d.reference));
      refs.add(chat.reference);
    }

    // Commit owned-data deletes in safe-sized chunks.
    for (var i = 0; i < refs.length; i += 400) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    // The profile document last, so any rule that keys off it still resolves
    // while the data above is being removed.
    await _firestore.collection(FirebaseConstants.users).doc(uid).delete();
  }

  Future<UserModel?> getCurrentUserData() async {
    final firebaseUser = _auth.currentUser;

    // user not logged in
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection(FirebaseConstants.users)
        .doc(firebaseUser.uid)
        .get();

    // user document not found
    if (!doc.exists) return null;

    // return UserModel.fromMap(doc.data()!);
    return UserModel.fromMap(doc.id, doc.data()!);
  }
}
