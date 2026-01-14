import 'package:blood_donation/Models/volunteer_model.dart';
import 'package:blood_donation/services/volunteer_service.dart';
import 'package:flutter/material.dart';

class VolunteerProvider with ChangeNotifier {
  final _service = VolunteerService();
  bool isloading = false;
  Future<void> addVolunteer(VolunteerModel volunteer) async {
    isloading = true;
    notifyListeners();
    _service.addVolunteer(volunteer);
    isloading = true;
    notifyListeners();
  }

  Stream<List<VolunteerModel>> get volunteerRequests => _service.getVolunteers();
}
