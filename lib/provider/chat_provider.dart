import 'dart:io';

import 'package:blood_donation/core/base/base_state_provider.dart';
import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/chat_service.dart';

class MessageProvider extends BaseStateProvider {
  MessageProvider({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  Stream<List<ChatModel>> getChatList() => _service.chatListStream();

  Stream<List<MessageModel>> getMessages(String receiverId) =>
      _service.getMessages(receiverId: receiverId);

  Stream<int> getTotalUnreadCount() => _service.totalUnreadCountStream();

  Future<UserModel?> getUserData(String userId) => _service.getUserById(userId);

  // Note: this provider holds no mutable state — the UI renders straight from
  // the Firestore streams above. So these mutators intentionally do NOT call
  // notifyListeners(); doing so just forces needless rebuilds of every
  // Consumer<MessageProvider> (and the chat ListView) on each send/read.
  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    await _service.sendMessage(reciverid: receiverId, text: text);
  }

  /// Upload + send an image/video attachment.
  Future<void> sendMediaMessage(
    String receiverId,
    File file,
    MessageType type, {
    String caption = '',
  }) async {
    await _service.sendMediaMessage(
      reciverid: receiverId,
      file: file,
      type: type,
      caption: caption,
    );
  }

  Future<void> markAsRead(String receiverId) async {
    await _service.markAsRead(receiverId);
  }

  /// Delete entire chat
  Future<void> deleteChat(String receiverId) async {
    await _service.deleteChat(receiverId);
  }

  /// Delete single message
  Future<void> deleteMessage(String receiverId, String messageId) async {
    await _service.deleteMessage(receiverId, messageId);
  }
}
