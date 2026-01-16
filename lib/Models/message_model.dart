import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final Timestamp? createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'text': text, 'createdAt': createdAt};
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'],
      text: map['text'],
      createdAt: map['createdAt'],
    );
  }
}
