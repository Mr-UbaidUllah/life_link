import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/user_tile_widget.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:blood_donation/widgets/shimmer.dart';
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

  // Cache the chat-list stream so the Consumer rebuilding (e.g. after a
  // deleteChat notify) doesn't resubscribe and flash the skeleton.
  late Stream<List<ChatModel>> _chatListStream;

  // Memoize per-user lookups; without this the FutureBuilder re-fetches every
  // user's doc on each chat-list snapshot emission.
  final Map<String, Future<UserModel?>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _chatListStream = context.read<MessageProvider>().getChatList();
  }

  Future<void> _refresh() async {
    // Re-subscribe and drop cached user lookups so names/avatars re-fetch too.
    setState(() {
      _userCache.clear();
      _chatListStream = context.read<MessageProvider>().getChatList();
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<UserModel?> _userFor(String uid) {
    return _userCache.putIfAbsent(
      uid,
      () => context.read<MessageProvider>().getUserData(uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16.w,
        // Search lives in the toolbar itself so there's no empty header band
        // above it — the inbox is search-first.
        title: SizedBox(
          height: 42.h,
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
            textAlignVertical: TextAlignVertical.center,
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Search messages',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14.sp),
              prefixIcon: Icon(Icons.search_rounded, size: 20.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: theme.colorScheme.primary,
        child: Consumer<MessageProvider>(
        builder: (context, chatProvider, _) {
          return StreamBuilder<List<ChatModel>>(
            stream: _chatListStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerList(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  itemCount: 8,
                  separator: 8.h,
                  itemBuilder: (_, __) => const UserTileSkeleton(dense: true),
                );
              }

              if (snapshot.hasError) {
                return RefreshableFill(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return RefreshableFill(child: _buildEmptyState(theme));
              }

              final chats = snapshot.data!;

              final filteredChats = chats.where((chat) {
                // Hide self-chats ("Saved Messages").
                if (chat.users.length == 2 && chat.users[0] == chat.users[1]) {
                  return false;
                }
                // Hide empty conversations — a chat with no message was never a
                // real conversation (e.g. a leftover phantom doc). Real chats
                // always carry the last message text.
                if (chat.lastMessage.trim().isEmpty) {
                  return false;
                }
                return true;
              }).toList();

              if (filteredChats.isEmpty) {
                return RefreshableFill(child: _buildEmptyState(theme));
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: filteredChats.length,
                separatorBuilder: (context, index) => SizedBox(height: 8.h),
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  final List<String> users = chat.users;
                  
                  String otherUserId = users.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => currentUserId!,
                  );

                  return FutureBuilder<UserModel?>(
                    future: _userFor(otherUserId),
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
                              content: Text('Are you sure you want to delete your conversation with $displayName?', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
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
                        child: UserTile(
                          dense: true,
                          showChevron: false,
                          name: displayName,
                          imageUrl: user.profileImage,
                          subtitle: chat.lastMessage.isEmpty ? 'Say hello 👋' : chat.lastMessage,
                          time: chat.updatedAt != null ? relativeTime(chat.updatedAt!.toDate()) : null,
                          unreadCount: unreadCount,
                          highlightSubtitle: unreadCount > 0,
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
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 44.sp,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Your chats with donors and requesters\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
