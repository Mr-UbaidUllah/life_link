import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/widgets/user_tile_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:blood_donation/provider/chat_provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Messages', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search chats...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, chatProvider, _) {
          return StreamBuilder<List<ChatModel>>(
            stream: chatProvider.getChatList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      ),
                    ],
                  ),
                );
              }

              final chats = snapshot.data!;
              
              final filteredChats = chats.where((chat) {
                if (chat.users.length == 2 && chat.users[0] == chat.users[1]) {
                  return false;
                }
                return true;
              }).toList();

              if (filteredChats.isEmpty) {
                return Center(
                  child: Text('No conversations yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                itemCount: filteredChats.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  final List<String> users = chat.users;
                  
                  String otherUserId = users.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => currentUserId!,
                  );

                  return FutureBuilder<UserModel?>(
                    future: chatProvider.getUserData(otherUserId),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      final user = userSnapshot.data;
                      if (user == null) return const SizedBox.shrink();

                      final displayName = user.name ?? 'Unknown';

                      if (_searchQuery.isNotEmpty && 
                          !displayName.toLowerCase().contains(_searchQuery)) {
                        return const SizedBox.shrink();
                      }

                      final unreadCount = chat.unreadCounts[currentUserId] ?? 0;

                      return Dismissible(
                        key: Key(chat.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          color: theme.colorScheme.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: theme.colorScheme.surface,
                              title: Text('Delete Chat', style: TextStyle(color: theme.colorScheme.onSurface)),
                              content: Text('Are you sure you want to delete your conversation with $displayName?', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          chatProvider.deleteChat(otherUserId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chat with $displayName deleted')),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            UserTile(
                              name: displayName,
                              imageUrl: user.profileImage,
                              subtitle: unreadCount > 0 
                                  ? '$unreadCount unread messages' 
                                  : chat.lastMessage,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      name: user.name ?? 'Unknown',
                                      imageUrl: user.profileImage,
                                      receiverId: user.uid,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (unreadCount > 0)
                              Padding(
                                padding: EdgeInsets.only(right: 20.w),
                                child: Container(
                                  width: 10.r,
                                  height: 10.r,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
