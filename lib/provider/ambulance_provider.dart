import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/services/ambulance_service.dart';

class AmbulanceProvider extends BaseStateProvider {
  AmbulanceProvider({AmbulanceService? service})
      : _service = service ?? AmbulanceService();

  final AmbulanceService _service;

  Future<bool> addAmbulance(AmbulanceModel ambulance) async {
    final result = await runGuarded<bool>(
      () async {
        await _service.addAmbulance(ambulance);
        return true;
      },
      errorContext: 'addAmbulance',
    );
    return result ?? false;
  }

  Stream<List<AmbulanceModel>> get ambulanceRequest => _service.getAmbulances();
}
