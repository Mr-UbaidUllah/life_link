import 'package:blood_donation/Models/organization_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationService {
  final _firestore = FirebaseFirestore.instance;
  Future<void> addOrganization(OrganizationModel orgmodel) async {
    _firestore.collection('organizations').add(orgmodel.toMap());
  }
}
