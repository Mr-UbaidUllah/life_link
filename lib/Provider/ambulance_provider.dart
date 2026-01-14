import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/services/ambulance_service.dart';
import 'package:flutter/material.dart';

class AmbulanceProvider with ChangeNotifier {
  final _service = AmbulanceService();
  bool isLoading = false;
  Future<void> addAmbulance(AmbulanceModel ambulance) async {
    isLoading = true;
    notifyListeners();
    await _service.addAmbulance(ambulance);
    isLoading = false;
    notifyListeners();
  }

  Stream<List<AmbulanceModel>> get ambulanceRequest => _service.getAmbulances();
}
