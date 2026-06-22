import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/services/volunteer_service.dart';

class VolunteerProvider extends BaseStateProvider {
  VolunteerProvider({VolunteerService? service})
      : _service = service ?? VolunteerService();

  final VolunteerService _service;

  Future<bool> addVolunteer(VolunteerModel volunteer) async {
    final result = await runGuarded<bool>(
      () async {
        await _service.addVolunteer(volunteer);
        return true;
      },
      errorContext: 'addVolunteer',
    );
    return result ?? false;
  }

  Stream<List<VolunteerModel>> get volunteerRequests => _service.getVolunteers();
}
