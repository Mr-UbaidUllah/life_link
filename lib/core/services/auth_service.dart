import 'package:blood_donation/Models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

    // Save to Firestore
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .set(userModel.toMap());

    // return credentialllls
    return userCredential;
  }

  Future<void> Login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
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
