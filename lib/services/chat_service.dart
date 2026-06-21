import 'package:blood_donation/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    // A message to yourself ("Saved Messages") must NOT bump an unread count —
    // the inbox hides self-chats, so that badge could never be cleared and
    // would stick forever on the bottom-nav.
    final bool isSelfChat = senderId == reciverid;

    //  CREATE/UPDATE CHAT
    // Increment unread count for the receiver
    // NOTE: dot-notation keys ('unreadCounts.$reciverid') are only interpreted
    // as nested field paths by update(); inside set(merge:true) they create a
    // literal top-level field with a dot in its name, so the count the inbox
    // reads (the nested `unreadCounts` map) never moved. Use a nested map —
    // merge:true deep-merges it, incrementing only the receiver's entry.
    await chatRef.set({
      'users': ids,
      'lastMessage': text,
      'updatedAt': timestamp,
      if (!isSelfChat) 'unreadCounts': {reciverid: FieldValue.increment(1)},
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

    final ref = _firestore.collection('chats').doc(chatRoomId);

    // Only clear the unread counter if a real conversation already exists.
    // This used to set+merge unconditionally, which CREATED an empty chat doc
    // just from opening a chat screen. That phantom (no lastMessage, null
    // updatedAt) floated to the top of the inbox AND reappeared right after a
    // conversation was deleted (reopening recreated it). No message yet → there
    // is nothing to mark read, so do nothing.
    final snap = await ref.get();
    if (!snap.exists) return;

    await ref.set({
      'unreadCounts': {currentUserId: 0},
    }, SetOptions(merge: true));
  }

  Future<void> _sendNotification(String receiverId, String text, String senderId) async {
    try {
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'New Message';

      // Write to the receiver's notifications subcollection. This both populates
      // the in-app notification inbox AND triggers the `sendChatPushNotification`
      // Cloud Function, which looks up the receiver's fcmToken server-side and
      // delivers the FCM push. (Clients can't send FCM to another device, so the
      // push MUST be server-side — never gate this write on a token.)
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'receiverId': receiverId,
        'title': senderName,
        'body': text,
        'senderId': senderId,
        'type': 'chat',
        'isRead': false,
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
