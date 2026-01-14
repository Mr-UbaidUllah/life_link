import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/services/userPost_service.dart';
import 'package:flutter/material.dart';

class UserPostsProvider with ChangeNotifier {
  final UserPostsService _service = UserPostsService();

  Stream<List<BloodRequestModel>> posts(String userId) =>
      _service.getUserPosts(userId);
}
