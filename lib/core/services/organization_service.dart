import 'package:blood_donation/Models/organization_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationService {
  final _firestore = FirebaseFirestore.instance;
  Future<void> addOrganization(OrganizationModel orgmodel) async {
    _firestore
        .collection('organizations')
        .doc(orgmodel.id)
        .set(orgmodel.toMap());
  }

  Stream<List<OrganizationModel>> getOrganizations() {
    return _firestore.collection('organizations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrganizationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
