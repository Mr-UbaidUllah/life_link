import 'package:blood_donation/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // 🔹 Messages area (will be used later)
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: Text(
                  'Messages will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),

          // 🔹 Input area
          Consumer<ChatProvider>(
            builder: (context, chatProvider, _) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: chatProvider.isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: chatProvider.isSending
                          ? null
                          : () async {
                              await context.read<ChatProvider>().sendMessage(
                                otherUserId: widget.otherUserId,
                                text: _messageController.text,
                              );

                              _messageController.clear();
                            },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
