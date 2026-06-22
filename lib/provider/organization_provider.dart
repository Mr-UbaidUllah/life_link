import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/models/organization_model.dart';
import 'package:blood_donation/services/organization_service.dart';

class OrganizationProvider extends BaseStateProvider {
  OrganizationProvider({OrganizationService? service})
      : _service = service ?? OrganizationService();

  final OrganizationService _service;

  Future<bool> addOraganization(OrganizationModel orgmodel) async {
    final result = await runGuarded<bool>(
      () async {
        await _service.addOrganization(orgmodel);
        return true;
      },
      errorContext: 'addOrganization',
    );
    return result ?? false;
  }

  Stream<List<OrganizationModel>> get requests => _service.getOrganizations();
}
