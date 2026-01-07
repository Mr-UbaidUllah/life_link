import 'package:blood_donation/Models/volunteer_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVolunteer(VolunteerModel volunteer) async {
    await _firestore
        .collection('Volunteer')
        .doc(volunteer.id)
        .set(volunteer.toMap());
  }

  Stream<List<VolunteerModel>> getVolunteers() {
    return _firestore.collection('Volunteer').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VolunteerModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
