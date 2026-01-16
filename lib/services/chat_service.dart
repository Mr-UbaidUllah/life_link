import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate SAME chatId for two users
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return sorted.join('_');
  }

  Future<String> createChatIfNotExists(String otherUserId) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = getChatId(myUid, otherUserId);

    final chatRef = _firestore.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();

    if (!snapshot.exists) {
      final chat = ChatModel(
        id: chatId,
        users: [myUid, otherUserId],
        lastMessage: '',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await chatRef.set(chat.toMap());
    }

    return chatId;
  }

  /// Send message
  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: myUid,
      text: text,
      createdAt: Timestamp.now(),
    );

    await messageRef.set(message.toMap());

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'updatedAt': Timestamp.now(),
    });
  }
}
