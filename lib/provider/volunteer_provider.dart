import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/services/volunteer_service.dart';
import 'package:flutter/material.dart';

class VolunteerProvider with ChangeNotifier {
  final _service = VolunteerService();
  bool isLoading = false;
  
  Future<void> addVolunteer(VolunteerModel volunteer) async {
    isLoading = true;
    notifyListeners();
    
    try {
      await _service.addVolunteer(volunteer);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<VolunteerModel>> get volunteerRequests => _service.getVolunteers();
}
