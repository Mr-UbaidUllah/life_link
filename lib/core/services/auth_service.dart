import 'package:blood_donation/Models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signup(String email, String password) async {
    // Create user in Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user model
    UserModel userModel = UserModel(
      uid: userCredential.user!.uid,
      email: email,
      createdAt: DateTime.now(),
    );

    // Save to Firestore
    await _firestore
        .collection('users')
        .doc(userModel.uid)
        .set(userModel.toMap());

    // return credentialllls
    return userCredential;
  }
}
