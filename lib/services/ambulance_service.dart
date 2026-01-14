import 'package:blood_donation/Models/ambulance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AmbulanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ADD AMBULANCE
  Future<void> addAmbulance(AmbulanceModel ambulance) async {
    await _firestore
        .collection('Ambulance')
        .doc(ambulance.id)
        .set(ambulance.toMap());
  }

  /// GET AMBULANCES STREAM
  Stream<List<AmbulanceModel>> getAmbulances() {
    return _firestore.collection('Ambulance').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AmbulanceModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
