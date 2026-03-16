import 'dart:convert';
import 'package:blood_donation/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch all chats for the current user
  Stream<QuerySnapshot> getChats() {
    final uid = _auth.currentUser?.uid;
    return _firestore
        .collection('chats')
        .where('users', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Send message
  Future<void> sendMessage({
    required String reciverid,
    required String text,
  }) async {
    final currentUser = _auth.currentUser!;
    final senderId = currentUser.uid;
    final senderEmail = currentUser.email!;
    final Timestamp timestamp = Timestamp.now();

    // chatId
    List<String> ids = [senderId, reciverid];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatRoomId);

    //  CREATE/UPDATE CHAT
    // Increment unread count for the receiver
    await chatRef.set({
      'users': ids, 
      'lastMessage': text,
      'updatedAt': timestamp,
      'unreadCounts.$reciverid': FieldValue.increment(1),
    }, SetOptions(merge: true));

    //  ADD MESSAGE
    MessageModel newMessage = MessageModel(
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: reciverid,
      text: text,
      createdAt: Timestamp.now(), 
      isDelivered: false,
    );

    await chatRef.collection('messages').add(newMessage.toMap());

    // Send Notification
    if (senderId != reciverid) {
       _sendNotification(reciverid, text, senderId);
    }
  }

  /// Mark chat as read
  Future<void> markAsRead(String receiverId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore.collection('chats').doc(chatRoomId).update({
      'unreadCounts.$currentUserId': 0,
    });
  }

  Future<void> _sendNotification(String receiverId, String text, String senderId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      
      if (!userDoc.exists) return;
      
      final fcmToken = userDoc.data()?['fcmToken'];
      final senderName = senderDoc.data()?['name'] ?? 'New Message';

      if (fcmToken == null) return;

      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'title': senderName,
        'body': text,
        'senderId': senderId,
        'type': 'chat',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  Stream<List<MessageModel>> getMessages({required String receiverId}) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final senderId = currentUser.uid;

    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    return chatRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data);
      }).toList();
    });
  }

  Future<void> deleteChat(String receiverId) async {
    final senderId = _auth.currentUser!.uid;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatRoomId);
    
    final messages = await chatRef.collection('messages').get();
    for (var doc in messages.docs) {
      await doc.reference.delete();
    }
    
    await chatRef.delete();
  }

  Future<void> deleteMessage(String receiverId, String messageId) async {
    final senderId = _auth.currentUser!.uid;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
