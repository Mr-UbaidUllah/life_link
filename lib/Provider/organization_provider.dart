import 'package:blood_donation/services/organization_service.dart';
import 'package:blood_donation/models/organization_model.dart';
import 'package:flutter/material.dart';

class OrganizationProvider with ChangeNotifier {
  final _service = OrganizationService();
  bool isLoading = false;

  Future<void> addOraganization(OrganizationModel orgmodel) async {
    isLoading = true;
    notifyListeners();
    await _service.addOrganization(orgmodel);
    isLoading = false;
    notifyListeners();
  }

  Stream<List<OrganizationModel>> get requests => _service.getOrganizations();
}
