import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/services/chat_service.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  Stream<List<MessageModel>> getMessages(String receiverId) {
    return _service.getMessages(receiverId: receiverId);
  }

  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    await _service.sendMessage(reciverid: receiverId, text: text);
  }
}
