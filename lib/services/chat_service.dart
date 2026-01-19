import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate SAME chatId for two users
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  // Future<String> createChatIfNotExists(String otherUserId) async {
  //   final myUid = FirebaseAuth.instance.currentUser!.uid;
  //   final chatId = getChatId(myUid, otherUserId);

  //   final chatRef = _firestore.collection('chats').doc(chatId);
  //   final snapshot = await chatRef.get();

  //   if (!snapshot.exists) {
  //     final chat = ChatModel(
  //       id: chatId,
  //       users: [myUid, otherUserId],
  //       lastMessage: '',
  //       createdAt: Timestamp.now(),
  //       updatedAt: Timestamp.now(),
  //     );
  //     await chatRef.set(chat.toMap());
  //   }

  //   return chatId;
  // }

  /// Send message
  Future<void> sendMessage({
    required String reciverid,
    required String text,
  }) async {
    final currentUser = _auth.currentUser!;
    final senderId = currentUser.uid;
    final senderEmail = currentUser.email!;
    final Timestamp timestamp = Timestamp.now();

    // 🔹 chatId
    List<String> ids = [senderId, reciverid];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatRoomId);

    //  CREATE CHAT IF NOT EXISTS
    await chatRef.set({
      'users': ids,
      'lastMessage': text,
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    // 🔹 ADD MESSAGE
    MessageModel newMessage = MessageModel(
      senderId: senderId,
      senderEmail: senderEmail,
      receiverId: reciverid,
      text: text,
    );

    await chatRef.collection('messages').add(newMessage.toMap());
  }

  Stream<List<MessageModel>> getMessages({required String receiverId}) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final senderId = currentUser.uid;

    // 🔹 Compute chat ID (same as sendMessage)
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: false);

    // 🔹 Return a stream of MessageModel
    return chatRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel.fromMap(data);
      }).toList();
    });
  }

  // Future<void> sendMessage({
  //   required String reciverid,
  //   required String text,
  // }) async {
  //   final currentuserid = _auth.currentUser!.uid;
  //   final currentuserEmail = _auth.currentUser!.email!;
  //   final Timestamp timestamp = Timestamp.now();

  //   MessageModel newMessage = MessageModel(
  //     senderId: currentuserid,
  //     senderEmail: currentuserEmail,
  //     receiverId: reciverid,
  //     text: text,
  //   );
  //   List<String> ids = [currentuserid, reciverid];
  //   ids.sort();
  //   String chatRoomid = ids.join('_');

  //   await _firestore
  //       .collection('chats')
  //       .doc(chatRoomid)
  //       .collection('messages')
  //       .add(newMessage.toMap());
  // }
}
