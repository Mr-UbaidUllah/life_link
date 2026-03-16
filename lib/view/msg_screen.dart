import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/view/profile/profile_details_scrren.dart';
import 'package:blood_donation/widgets/message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final String receiverId;

  const ChatScreen({
    super.key,
    required this.name,
    this.imageUrl,
    required this.receiverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark as read when entering the chat
    Future.microtask(() {
      if (mounted) {
        context.read<MessageProvider>().markAsRead(widget.receiverId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSavedMessages = widget.receiverId == currentUserId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: isSavedMessages ? null : _viewProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                backgroundImage:
                    widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? NetworkImage(widget.imageUrl!)
                    : null,
                child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                    ? Icon(Icons.person, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 20.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSavedMessages ? "Saved Messages" : widget.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isSavedMessages)
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            onPressed: () => _showChatOptions(context, theme),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                return StreamBuilder<List<MessageModel>>(
                  stream: messageProvider.getMessages(widget.receiverId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                            SizedBox(height: 16.h),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!.reversed.toList();

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return MessageBubble(message: messages[index]);
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildInputSection(theme),
        ],
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, MediaQuery.of(context).padding.bottom + 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(fontSize: 15.sp, color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 14.sp),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () => _sendMessage(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    context.read<MessageProvider>().sendMessage(
      widget.receiverId,
      text,
    );

    _controller.clear();
    _scrollToBottom();
  }

  void _viewProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(userId: widget.receiverId),
      ),
    );
  }

  void _showChatOptions(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                height: 4.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_outline, color: theme.colorScheme.onSurface),
                title: Text('View Profile', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(context);
                  _viewProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat(context, theme);
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteChat(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete Chat', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to delete all messages?', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await context.read<MessageProvider>().deleteChat(widget.receiverId);
                if (mounted) {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error deleting chat: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
