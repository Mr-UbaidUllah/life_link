import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/services/blood_group_service.dart';
import 'package:flutter/material.dart';

class BloodGroupRequestProvider with ChangeNotifier {
  BloodGroupRequestProvider({BloodgroupService? service})
      : _service = service ?? BloodgroupService();

  final BloodgroupService _service;

  /// Stream for posts filtered by blood group (used when clicking GridView)
  Stream<List<BloodRequestModel>> postsByBloodGroup(String bloodGroup) {
    return _service.getPostsByBloodGroup(bloodGroup);
  }
}
