import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String text;
  final Timestamp createdAt;
  final bool isDelivered; // NEW

  MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isDelivered = false, // default false
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt,
      'isDelivered': isDelivered, // save to Firestore
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'],
      senderEmail: map['senderEmail'],
      receiverId: map['receiverId'],
      text: map['text'],
      createdAt: map['createdAt'],
      isDelivered: map['isDelivered'] ?? false,
    );
  }
}
