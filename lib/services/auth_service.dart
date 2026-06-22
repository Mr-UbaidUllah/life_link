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
