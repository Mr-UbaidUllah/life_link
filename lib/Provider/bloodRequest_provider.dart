import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:blood_donation/services/bloodrequesT_Service.dart';
import 'package:flutter/material.dart';

class BloodrequestProvider with ChangeNotifier {
  final _service = BloodrequestService();
  List<BloodRequestModel> _allRequests = [];
  List<BloodRequestModel> _filteredRequests = [];
  bool isLoading = false;

  Future<void> bloodRequest(BloodRequestModel request) async {
    isLoading = true;
    notifyListeners();

    await _service.createRequest(request);

    isLoading = false;
    notifyListeners();
  }

  List<BloodRequestModel> get filteredrequests => _filteredRequests;

  Stream<List<BloodRequestModel>> get requests => _service.getRequets();

  /// Called when Firestore sends data

  void setRequests(List<BloodRequestModel> list) {
    _allRequests = list;
    _filteredRequests = list; // show all by default
    notifyListeners();
  }

  /// Filter by blood group
  void searchByBlood(String query) {
    if (query.isEmpty) {
      _filteredRequests = _allRequests;
    } else {
      _filteredRequests = _allRequests
          .where(
            (r) => r.bloodGroup.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
      notifyListeners();
    }
    notifyListeners();
  }
}
