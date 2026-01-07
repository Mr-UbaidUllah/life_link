import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:blood_donation/core/services/bloodGroup_Service.dart';
import 'package:flutter/material.dart';

class BloodGroupRequestProvider with ChangeNotifier {
  final BloodgroupService _service = BloodgroupService();

  /// Stream for posts filtered by blood group (used when clicking GridView)
  Stream<List<BloodRequestModel>> postsByBloodGroup(String bloodGroup) {
    return _service.getPostsByBloodGroup(bloodGroup);
  }
}
