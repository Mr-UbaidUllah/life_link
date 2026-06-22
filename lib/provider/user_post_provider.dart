import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/services/user_post_service.dart';
import 'package:flutter/material.dart';

class UserPostsProvider with ChangeNotifier {
  UserPostsProvider({UserPostsService? service})
      : _service = service ?? UserPostsService();

  final UserPostsService _service;

  Stream<List<BloodRequestModel>> posts(String userId) =>
      _service.getUserPosts(userId);
}
