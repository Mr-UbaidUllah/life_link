import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get chats => _service.getChats();

  Stream<List<ChatModel>> getChatList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final chatList = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
          .toList();
      
      chatList.sort((a, b) {
        final timeA = a.updatedAt ?? Timestamp.now();
        final timeB = b.updatedAt ?? Timestamp.now();
        return timeB.compareTo(timeA);
      });
      
      return chatList;
    });
  }

  Stream<List<MessageModel>> getMessages(String receiverId) {
    return _service.getMessages(receiverId: receiverId);
  }

  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    await _service.sendMessage(reciverid: receiverId, text: text);
    notifyListeners();
  }

  Future<void> markAsRead(String receiverId) async {
    await _service.markAsRead(receiverId);
    notifyListeners();
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  /// Delete entire chat
  Future<void> deleteChat(String receiverId) async {
    try {
      await _service.deleteChat(receiverId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting chat in provider: $e');
      rethrow;
    }
  }

  /// Delete single message
  Future<void> deleteMessage(String receiverId, String messageId) async {
    await _service.deleteMessage(receiverId, messageId);
    notifyListeners();
  }

  /// Get total unread count for the current user
  Stream<int> getTotalUnreadCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
        total += unreadCounts[uid] ?? 0;
      }
      return total;
    });
  }
}
