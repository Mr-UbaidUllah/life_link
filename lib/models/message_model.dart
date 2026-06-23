import 'package:cloud_firestore/cloud_firestore.dart';

/// Kind of message. Older documents have no `type` field and decode as [text],
/// so existing chats keep working unchanged.
enum MessageType {
  text,
  image,
  video;

  static MessageType fromName(String? name) => switch (name) {
        'image' => MessageType.image,
        'video' => MessageType.video,
        _ => MessageType.text,
      };
}

class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;

  /// For media messages this holds an optional caption (may be empty).
  final String text;
  final Timestamp createdAt;
  final bool isDelivered;

  /// text / image / video.
  final MessageType type;

  /// Download URL of the attached image or video (null for text messages).
  final String? mediaUrl;

  MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isDelivered = false,
    this.type = MessageType.text,
    this.mediaUrl,
  });

  bool get isMedia => type != MessageType.text;

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'text': text,
      'createdAt': createdAt,
      'isDelivered': isDelivered,
      'type': type.name,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      isDelivered: map['isDelivered'] ?? false,
      type: MessageType.fromName(map['type'] as String?),
      mediaUrl: map['mediaUrl'] as String?,
    );
  }
}
