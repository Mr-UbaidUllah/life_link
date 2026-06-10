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

      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ FCM Token saved for user");
    } catch (e) {
      print("❌ Error saving FCM token: $e");
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
          .collection('users')
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

  Future<void> Login(String email, String password) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // SAVE / UPDATE FCM TOKEN AFTER LOGIN
    await _saveFcmToken(userCredential.user!.uid);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUserData() async {
    final firebaseUser = _auth.currentUser;

    // user not logged in
    if (firebaseUser == null) return null;

    final doc = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    // user document not found
    if (!doc.exists) return null;

    // return UserModel.fromMap(doc.data()!);
    return UserModel.fromMap(doc.id, doc.data()!);
  }
}
