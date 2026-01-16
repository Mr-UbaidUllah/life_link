import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> users;
  final String lastMessage;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ChatModel({
    required this.id,
    required this.users,
    required this.lastMessage,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatModel(
      id: id,
      users: List<String>.from(map['users']),
      lastMessage: map['lastMessage'] ?? '',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}
