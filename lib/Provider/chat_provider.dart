import 'package:flutter/material.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  bool isSending = false;
  String? currentChatId;

  /// Create chat + send message
  Future<void> sendMessage({
    required String otherUserId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    isSending = true;
    notifyListeners();

    try {
      // 1️⃣ Create or get chat
      currentChatId = await _chatService.createChatIfNotExists(otherUserId);

      // 2️⃣ Send message
      await _chatService.sendMessage(chatId: currentChatId!, text: text.trim());
    } catch (e) {
      debugPrint('Send message error: $e');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
