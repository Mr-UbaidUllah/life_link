import 'package:blood_donation/models/chat_models.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
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

/// Inbox filter tabs.
enum _Filter { all, unread }

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _Filter _filter = _Filter.all;

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Real conversations only: drop self-chats and never-started threads.
  List<ChatModel> _visibleChats(List<ChatModel> chats, String? currentUserId) {
    return chats.where((chat) {
      if (chat.users.length == 2 && chat.users[0] == chat.users[1]) {
        return false;
      }
      if (chat.lastMessage.trim().isEmpty) return false;
      if (_filter == _Filter.unread &&
          (chat.unreadCounts[currentUserId] ?? 0) == 0) {
        return false;
      }
      return true;
    }).toList();
  }

  String _otherUserId(ChatModel chat, String? currentUserId) {
    return chat.users.firstWhere(
      (id) => id != currentUserId,
      orElse: () => currentUserId ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: theme.colorScheme.primary,
          child: Consumer<MessageProvider>(
            builder: (context, chatProvider, _) {
              return StreamBuilder<List<ChatModel>>(
                stream: _chatListStream,
                builder: (context, snapshot) {
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final allChats =
                      _visibleChats(snapshot.data ?? const [], currentUserId);
                  final totalUnread = allChats.fold<int>(
                      0,
                      (sum, c) =>
                          sum + (c.unreadCounts[currentUserId] ?? 0));

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    slivers: [
                      _buildHeaderSliver(theme, totalUnread),
                      _buildSearchSliver(theme),
                      _buildFilterSliver(theme),
                      if (loading)
                        _buildLoadingSliver()
                      else if (snapshot.hasError)
                        _buildMessageSliver(
                          theme,
                          icon: Icons.error_outline_rounded,
                          title: 'Something went wrong',
                          subtitle: '${snapshot.error}',
                        )
                      else ...[
                        if (_searchQuery.isEmpty &&
                            _filter == _Filter.all &&
                            allChats.length >= 5)
                          _buildRecentStripSliver(
                              theme, allChats, currentUserId),
                        if (allChats.isEmpty)
                          _buildMessageSliver(
                            theme,
                            icon: _filter == _Filter.unread
                                ? Icons.mark_chat_read_outlined
                                : Icons.forum_outlined,
                            title: _filter == _Filter.unread
                                ? 'All caught up'
                                : 'No conversations yet',
                            subtitle: _filter == _Filter.unread
                                ? 'You have no unread messages.'
                                : 'Your chats with donors and requesters\nwill appear here.',
                          )
                        else
                          _buildListSliver(
                              theme, chatProvider, allChats, currentUserId),
                      ],
                      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  Widget _buildHeaderSliver(ThemeData theme, int totalUnread) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 6.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Messages',
              style:
                  theme.textTheme.headlineMedium?.copyWith(fontSize: 30.sp),
            ),
            SizedBox(width: 10.w),
            if (totalUnread > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(AppRadii.pill.r),
                ),
                child: Text(
                  '$totalUnread new',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Search
  // --------------------------------------------------------------------------

  Widget _buildSearchSliver(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
        child: TextField(
          controller: _searchController,
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase().trim()),
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: 'Search messages',
            prefixIcon: Icon(Icons.search_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            suffixIcon: _searchQuery.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close_rounded,
                        size: 18.sp,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Filter chips
  // --------------------------------------------------------------------------

  Widget _buildFilterSliver(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 6.h),
        child: Row(
          children: [
            _filterChip(theme, 'All', _Filter.all),
            SizedBox(width: 8.w),
            _filterChip(theme, 'Unread', _Filter.unread),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ThemeData theme, String label, _Filter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.hero : null,
          color: selected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          border: Border.all(
            color: selected ? Colors.transparent : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Recent contacts strip
  // --------------------------------------------------------------------------

  Widget _buildRecentStripSliver(
      ThemeData theme, List<ChatModel> chats, String? currentUserId) {
    final recent = chats.take(10).toList();
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: 6.h, bottom: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 10.h),
              child: Text(
                'Recent',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            SizedBox(
              height: 92.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: recent.length,
                separatorBuilder: (_, __) => SizedBox(width: 16.w),
                itemBuilder: (context, index) {
                  final chat = recent[index];
                  final otherId = _otherUserId(chat, currentUserId);
                  final unread = chat.unreadCounts[currentUserId] ?? 0;
                  return _RecentAvatar(
                    future: _userFor(otherId),
                    hasUnread: unread > 0,
                    onTap: (user) => _openChat(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Conversation list
  // --------------------------------------------------------------------------

  Widget _buildListSliver(ThemeData theme, MessageProvider chatProvider,
      List<ChatModel> chats, String? currentUserId) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      sliver: SliverList.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final otherUserId = _otherUserId(chat, currentUserId);
          final unreadCount = chat.unreadCounts[currentUserId] ?? 0;

          return FutureBuilder<UserModel?>(
            future: _userFor(otherUserId),
            builder: (context, userSnapshot) {
              final user = userSnapshot.data;
              if (user == null) return const SizedBox.shrink();

              final displayName = user.name ?? 'Unknown';
              if (_searchQuery.isNotEmpty &&
                  !displayName.toLowerCase().contains(_searchQuery)) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Dismissible(
                  key: Key(chat.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 22.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.white),
                  ),
                  confirmDismiss: (_) =>
                      _confirmDelete(theme, displayName),
                  onDismissed: (_) {
                    chatProvider.deleteChat(otherUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chat with $displayName deleted')),
                    );
                  },
                  child: _ConversationTile(
                    name: displayName,
                    imageUrl: user.profileImage,
                    lastMessage: chat.lastMessage.isEmpty
                        ? 'Say hello 👋'
                        : chat.lastMessage,
                    time: chat.updatedAt != null
                        ? relativeTime(chat.updatedAt!.toDate())
                        : '',
                    unreadCount: unreadCount,
                    onTap: () => _openChat(user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // State slivers (loading / empty / error)
  // --------------------------------------------------------------------------

  Widget _buildLoadingSliver() {
    // NOTE: a non-shrinkwrap ListView (ShimmerList) inside a SliverToBoxAdapter
    // has unbounded height and crashes layout. Render the skeletons as a
    // bounded Column wrapped in a single shimmer sweep instead.
    return SliverToBoxAdapter(
      child: AppShimmer(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            children: List.generate(
              7,
              (_) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: const UserTileSkeleton(dense: true),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageSliver(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(40.w, 40.h, 40.w, 80.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 44.sp,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7)),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------------------

  void _openChat(UserModel user) {
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
  }

  Future<bool?> _confirmDelete(ThemeData theme, String displayName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete Chat',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to delete your conversation with $displayName?',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Conversation row — chat-specific, structurally distinct from the shared
// UserTile (which is still used by Settings). Two-line layout with an unread
// ring on the avatar and an unread count pill.
// ===========================================================================

class _ConversationTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.name,
    required this.imageUrl,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = unreadCount > 0;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: hasUnread
                  ? theme.colorScheme.primary.withValues(alpha: 0.35)
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            children: [
              _Avatar(imageUrl: imageUrl, name: name, ringed: hasUnread),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w700,
                            color: hasUnread
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: theme.colorScheme.onSurface.withValues(
                                  alpha: hasUnread ? 0.85 : 0.5),
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          SizedBox(width: 8.w),
                          Container(
                            constraints: BoxConstraints(minWidth: 20.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              gradient: AppGradients.hero,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular avatar with an optional gradient unread ring.
class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final bool ringed;
  final double radius;

  const _Avatar({
    required this.imageUrl,
    required this.name,
    this.ringed = false,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final avatar = CircleAvatar(
      radius: radius.r,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: (radius * 0.62).sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
    );

    if (!ringed) return avatar;
    return Container(
      padding: EdgeInsets.all(2.5.r),
      decoration: const BoxDecoration(
        gradient: AppGradients.hero,
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: avatar,
      ),
    );
  }
}

/// One item in the horizontal "Recent" strip.
class _RecentAvatar extends StatelessWidget {
  final Future<UserModel?> future;
  final bool hasUnread;
  final void Function(UserModel user) onTap;

  const _RecentAvatar({
    required this.future,
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<UserModel?>(
      future: future,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return SizedBox(width: 56.w);
        }
        final name = user.name ?? 'Unknown';
        return GestureDetector(
          onTap: () => onTap(user),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 60.w,
            child: Column(
              children: [
                _Avatar(
                  imageUrl: user.profileImage,
                  name: name,
                  ringed: hasUnread,
                  radius: 27,
                ),
                SizedBox(height: 7.h),
                Text(
                  name.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
