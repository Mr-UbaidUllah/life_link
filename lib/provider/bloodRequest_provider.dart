import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/services/bloodrequesT_Service.dart';
import 'package:flutter/material.dart';

class BloodrequestProvider with ChangeNotifier {
  final _service = BloodRequestService();
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

  Future<void> updateStatus(String requestId, String status) async {
    isLoading = true;
    notifyListeners();

    await _service.updateRequestStatus(requestId, status);

    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRequest(String requestId) async {
    isLoading = true;
    notifyListeners();

    await _service.deleteRequest(requestId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> clearAllRequests() async {
    isLoading = true;
    notifyListeners();

    await _service.clearAllRequests();

    isLoading = false;
    notifyListeners();
  }

  List<BloodRequestModel> get filteredrequests => _filteredRequests;

  Stream<List<BloodRequestModel>> get requests => _service.getRequests();

  void setRequests(List<BloodRequestModel> list) {
    _allRequests = list;
    _filteredRequests = list;
    notifyListeners();
  }

  void searchByBlood(String query) {
    if (query.isEmpty) {
      _filteredRequests = _allRequests;
    } else {
      _filteredRequests = _allRequests
          .where(
            (r) => r.bloodGroup.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    notifyListeners();
  }
}
