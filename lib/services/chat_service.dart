import 'dart:io';

import 'package:blood_donation/core/constants/firebase_constants.dart';
import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/storage_service.dart';
import 'package:blood_donation/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  ChatService({StorageService? storage})
      : _storage = storage ?? StorageService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storage;

  /// Streams the current user's chats, newest-active first.
  Stream<List<ChatModel>> chatListStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _firestore
        .collection(FirebaseConstants.chats)
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      final chatList = snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
          .toList();

      chatList.sort((a, b) {
        // Newest first; chats with no updatedAt sink to the bottom.
        final timeA = a.updatedAt;
        final timeB = b.updatedAt;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA);
      });
      return chatList;
    });
  }

  /// Streams the total unread message count across all of the user's chats.
  Stream<int> totalUnreadCountStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection(FirebaseConstants.chats)
        .where('users', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final unreadCounts =
            Map<String, int>.from(doc.data()['unreadCounts'] ?? {});
        total += unreadCounts[uid] ?? 0;
      }
      return total;
    });
  }

  /// Looks up a user document by id (used to render chat headers/avatars).
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(FirebaseConstants.users).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }
    } catch (e) {
      AppLogger.e('getUserById failed', e);
    }
    return null;
  }

  /// Send a text message.
  Future<void> sendMessage({
    required String reciverid,
    required String text,
  }) async {
    await _deliver(
      reciverid: reciverid,
      text: text,
      type: MessageType.text,
    );
  }

  /// Upload an image/video attachment to Cloud Storage, then send it as a
  /// message. [caption] is optional and ride-alongs as the message text.
  Future<void> sendMediaMessage({
    required String reciverid,
    required File file,
    required MessageType type,
    String caption = '',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Cannot send a message while signed out.');
    }
    final senderId = currentUser.uid;

    List<String> ids = [senderId, reciverid];
    ids.sort();
    final chatRoomId = ids.join('_');

    final isVideo = type == MessageType.video;
    final ext = _extensionFor(file.path, fallback: isVideo ? 'mp4' : 'jpg');
    // Unique per-attachment name so multiple sends never collide.
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${senderId.substring(0, 6)}.$ext';

    final mediaUrl = await _storage.uploadFile(
      path: '${FirebaseConstants.chatMediaFolder}/$chatRoomId/$fileName',
      file: file,
      contentType: isVideo ? 'video/mp4' : 'image/jpeg',
    );

    await _deliver(
      reciverid: reciverid,
      text: caption,
      type: type,
      mediaUrl: mediaUrl,
    );
  }

  String _extensionFor(String path, {required String fallback}) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return fallback;
    final ext = path.substring(dot + 1).toLowerCase();
    // Guard against odd paths (e.g. content URIs) producing a junk extension.
    return ext.length <= 4 ? ext : fallback;
  }

  /// Short inbox/notification preview for a message of [type].
  String _preview(MessageType type, String text) => switch (type) {
        MessageType.image => text.isEmpty ? '📷 Photo' : '📷 $text',
        MessageType.video => text.isEmpty ? '🎥 Video' : '🎥 $text',
        MessageType.text => text,
      };

  /// Shared writer: updates the chat doc, appends the message and fires the
  /// notification. Used by both text and media sends.
  Future<void> _deliver({
    required String reciverid,
    required String text,
    required MessageType type,
    String? mediaUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Cannot send a message while signed out.');
    }
    final senderId = currentUser.uid;
    // email can be null for non-email auth providers — don't force-unwrap.
    final senderEmail = currentUser.email ?? '';
    final Timestamp timestamp = Timestamp.now();

    // chatId
    List<String> ids = [senderId, reciverid];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatRoomId);

    final preview = _preview(type, text);

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
    //  ADD MESSAGE
    MessageModel newMessage = MessageModel(
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: reciverid,
      text: text,
      createdAt: Timestamp.now(),
      isDelivered: false,
      type: type,
      mediaUrl: mediaUrl,
    );

    // Write the chat summary and the message atomically so the inbox can never
    // show a preview / bumped unread count for a message that failed to land.
    final batch = _firestore.batch();
    batch.set(chatRef, {
      'users': ids,
      'lastMessage': preview,
      'updatedAt': timestamp,
      if (!isSelfChat) 'unreadCounts': {reciverid: FieldValue.increment(1)},
    }, SetOptions(merge: true));
    batch.set(chatRef.collection('messages').doc(), newMessage.toMap());
    await batch.commit();

    // Send Notification
    if (senderId != reciverid) {
      _sendNotification(reciverid, preview, senderId);
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
      AppLogger.e('Error sending chat notification', e);
    }
  }

  Stream<List<MessageModel>> getMessages({required String receiverId}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream<List<MessageModel>>.empty();
    }
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
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) return;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatRoomId);

    // Delete messages in batched pages (max 500 writes/batch) instead of one
    // sequential await-per-doc loop, so large chats don't fan out into hundreds
    // of round-trips. The chat doc itself is deleted last.
    while (true) {
      final page = await chatRef.collection('messages').limit(400).get();
      if (page.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (page.docs.length < 400) break;
    }

    await chatRef.delete();
  }

  Future<void> deleteMessage(String receiverId, String messageId) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) return;
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
