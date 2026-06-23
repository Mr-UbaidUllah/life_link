import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/services/blood_request_service.dart';
import 'package:flutter/material.dart';

class BloodrequestProvider with ChangeNotifier {
  BloodrequestProvider({BloodRequestService? service})
      : _service = service ?? BloodRequestService();

  final BloodRequestService _service;
  bool isLoading = false;

  Future<void> bloodRequest(BloodRequestModel request) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.createRequest(request);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String requestId, String status) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.updateRequestStatus(requestId, status);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ ACCEPT BLOOD REQUEST
  Future<void> acceptBloodRequest(String requestId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.acceptRequest(requestId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ CANCEL ACCEPTANCE
  Future<void> cancelAcceptance(String requestId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.cancelAcceptance(requestId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ COMPLETE BLOOD REQUEST
  Future<void> completeBloodRequest(String requestId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.completeRequest(requestId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRequest(String requestId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.deleteRequest(requestId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAllRequests() async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.clearAllRequests();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Stream<List<BloodRequestModel>> get requests => _service.getRequests();
}
