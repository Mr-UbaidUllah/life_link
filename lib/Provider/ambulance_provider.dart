import 'package:blood_donation/Models/ambulance_model.dart';
import 'package:blood_donation/core/services/ambulance_service.dart';
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
}
