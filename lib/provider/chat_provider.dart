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

  Future<void> sendMessage(String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    await _service.sendMessage(reciverid: receiverId, text: text);
    notifyListeners();
  }

  Future<void> markAsRead(String receiverId) async {
    await _service.markAsRead(receiverId);
    notifyListeners();
  }

  /// Delete entire chat
  Future<void> deleteChat(String receiverId) async {
    await _service.deleteChat(receiverId);
    notifyListeners();
  }

  /// Delete single message
  Future<void> deleteMessage(String receiverId, String messageId) async {
    await _service.deleteMessage(receiverId, messageId);
    notifyListeners();
  }
}
