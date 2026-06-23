import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  /// The full raw document, kept so the detail screen can read type-specific
  /// metadata (senderId for chats, requestId for blood requests, etc.) without
  /// the model needing a field for every notification variant.
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  /// User id of whoever triggered the notification (chat sender, available
  /// donor). Null when the notification carries no associated user.
  /// Uses `is String` instead of `as String?` so a malformed (non-string)
  /// field can never throw a cast error from a getter.
  String? get senderId {
    final v = data['senderId'] ?? data['userId'];
    return v is String ? v : null;
  }

  /// Blood request this notification refers to, when [type] is `blood_request`.
  String? get requestId {
    final v = data['requestId'];
    return v is String ? v : null;
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      // createdAt is null in the local snapshot of a serverTimestamp write
      // until the server resolves it — fall back instead of crashing.
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      data: map,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}
