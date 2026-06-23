import 'dart:io';

import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/utils/image_limits.dart';
import 'package:blood_donation/view/media_preview_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/widgets/message_bubble.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
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

  // Cache the messages stream once — the provider getter opens a NEW Firestore
  // subscription on each call, so building it inline would resubscribe (and
  // flash the loading skeleton) every time the Consumer rebuilds on send.
  late final Stream<List<MessageModel>> _messagesStream;

  // Tracks how many messages we've already acknowledged as read. Each time the
  // stream grows while the chat is on screen we re-run markAsRead, otherwise an
  // incoming message would re-bump unreadCounts[me] and leave a phantom badge
  // on the bottom-nav until the user closed and reopened the chat.
  int _lastSeenCount = 0;

  // Guards against a message being sent twice from a double-tap / Enter+tap in
  // the same frame (the send button only disables on the next rebuild).
  bool _sending = false;

  final ImagePicker _picker = ImagePicker();

  // True while an attachment is uploading + sending; gates the input so a
  // second pick can't race the first.
  bool _sendingMedia = false;

  @override
  void initState() {
    super.initState();
    _messagesStream =
        context.read<MessageProvider>().getMessages(widget.receiverId);
    // Mark as read when entering the chat
    Future.microtask(() {
      if (mounted) {
        context.read<MessageProvider>().markAsRead(widget.receiverId);
      }
    });
  }

  /// Clear the unread count whenever the visible message list grows while the
  /// chat is open. Idempotent (markAsRead just sets the counter to 0).
  void _markReadIfNewMessages(int count) {
    // If the list ever shrinks (e.g. a deleted message), lower the watermark so
    // the next inbound message still re-triggers markAsRead instead of leaving
    // a phantom unread badge.
    if (count < _lastSeenCount) _lastSeenCount = count;
    if (count <= _lastSeenCount) return;
    _lastSeenCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      appBar: _buildHeader(theme, isSavedMessages),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, _, __) {
                return StreamBuilder<List<MessageModel>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const MessageListSkeleton();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(theme, isSavedMessages);
                    }

                    // Newest-first so the reversed ListView puts the latest
                    // message at the bottom.
                    final messages = snapshot.data!.reversed.toList();
                    _markReadIfNewMessages(snapshot.data!.length);

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _buildRow(theme, messages, index),
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

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------

  PreferredSizeWidget _buildHeader(ThemeData theme, bool isSavedMessages) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;
    return PreferredSize(
      preferredSize: Size.fromHeight(64.h),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.hero,
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33D7263D),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64.h,
            child: Row(
              children: [
                SizedBox(width: 4.w),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isSavedMessages ? null : _viewProfile,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 18.r,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            backgroundImage:
                                hasImage ? NetworkImage(widget.imageUrl!) : null,
                            child: hasImage
                                ? null
                                : Icon(
                                    isSavedMessages
                                        ? Icons.bookmark_rounded
                                        : Icons.person_rounded,
                                    color: Colors.white,
                                    size: 20.sp),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSavedMessages
                                    ? 'Saved Messages'
                                    : widget.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16.5.sp,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!isSavedMessages) ...[
                                SizedBox(height: 1.h),
                                Row(
                                  children: [
                                    Text(
                                      'View profile',
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 14.sp,
                                        color: Colors.white
                                            .withValues(alpha: 0.85)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showChatOptions(context, theme),
                ),
                SizedBox(width: 4.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Message rows (with grouping + date separators)
  // --------------------------------------------------------------------------

  Widget _buildRow(ThemeData theme, List<MessageModel> messages, int index) {
    final cur = messages[index];
    final older = index < messages.length - 1 ? messages[index + 1] : null;
    final newer = index > 0 ? messages[index - 1] : null;

    final startsDay = _startsNewDay(messages, index);
    final newerStartsDay = newer != null && _startsNewDay(messages, index - 1);

    final isFirstInGroup =
        startsDay || older == null || !_grouped(cur, older);
    final isLastInGroup =
        newer == null || newerStartsDay || !_grouped(cur, newer);

    final bubble = MessageBubble(
      message: cur,
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
      peerImageUrl: widget.imageUrl,
      peerName: widget.name,
    );

    if (!startsDay) return bubble;
    return Column(
      children: [
        _dateChip(theme, _dayLabel(cur.createdAt.toDate())),
        bubble,
      ],
    );
  }

  /// Two messages belong to the same visual group when the same person sent
  /// them within a short window.
  bool _grouped(MessageModel a, MessageModel b) {
    if (a.senderId != b.senderId) return false;
    final gap =
        a.createdAt.toDate().difference(b.createdAt.toDate()).abs();
    return gap.inMinutes < 3;
  }

  /// True if [messages] (newest-first) at [index] is the chronological first
  /// message of its day — i.e. the older neighbour is a different day.
  bool _startsNewDay(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    final cur = messages[index].createdAt.toDate();
    final older = messages[index + 1].createdAt.toDate();
    return cur.year != older.year ||
        cur.month != older.month ||
        cur.day != older.day;
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _dateChip(ThemeData theme, String label) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Empty state
  // --------------------------------------------------------------------------

  Widget _buildEmptyState(ThemeData theme, bool isSavedMessages) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                shape: BoxShape.circle,
                boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.3),
              ),
              child: Icon(
                isSavedMessages
                    ? Icons.bookmark_rounded
                    : Icons.waving_hand_rounded,
                size: 40.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isSavedMessages ? 'Your space' : 'Say hello',
              style: TextStyle(
                fontSize: 18.sp,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              isSavedMessages
                  ? 'Notes you send here are saved just for you.'
                  : 'Send the first message to start the conversation.',
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
  // Input
  // --------------------------------------------------------------------------

  Widget _buildInputSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8.w, 10.h, 12.w, MediaQuery.of(context).padding.bottom + 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sendingMedia) _uploadingBanner(theme),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment (image / video) trigger.
              GestureDetector(
                onTap: _sendingMedia ? null : _showAttachmentSheet,
                child: Container(
                  height: 46.r,
                  width: 46.r,
                  margin: EdgeInsets.only(right: 6.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: theme.colorScheme.primary,
                    size: 24.sp,
                  ),
                ),
              ),
              Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.xl.r),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 5,
                minLines: 1,
                style: TextStyle(
                    fontSize: 15.sp, color: theme.colorScheme.onSurface),
                // The pill container owns the fill + border, so the field's own
                // decoration must be fully transparent — otherwise the global
                // inputDecorationTheme (filled + bordered) paints a second box
                // inside this one.
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.4),
                      fontSize: 14.sp),
                  filled: false,
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Send button reflects whether there's anything to send.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText ? () => _sendMessage(context) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 46.r,
                  width: 46.r,
                  decoration: BoxDecoration(
                    gradient: hasText ? AppGradients.hero : null,
                    color: hasText
                        ? null
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    boxShadow: hasText
                        ? AppGradients.glow(AppColors.primary, alpha: 0.3)
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                    size: 20.sp,
                  ),
                ),
              );
            },
          ),
            ],
          ),
        ],
      ),
    );
  }

  /// Thin progress banner shown above the input while media uploads.
  Widget _uploadingBanner(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            height: 14.r,
            width: 14.r,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10.w),
          Text(
            'Sending attachment…',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Attachments (image / video)
  // --------------------------------------------------------------------------

  void _showAttachmentSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  alignment: Alignment.center,
                  child: Container(
                    height: 4.h,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    _attachOption(theme, sheetContext,
                        icon: Icons.photo_library_rounded,
                        label: 'Photo',
                        color: AppColors.info,
                        type: MessageType.image,
                        source: ImageSource.gallery),
                    SizedBox(width: 12.w),
                    _attachOption(theme, sheetContext,
                        icon: Icons.video_library_rounded,
                        label: 'Video',
                        color: AppColors.violet,
                        type: MessageType.video,
                        source: ImageSource.gallery),
                    SizedBox(width: 12.w),
                    _attachOption(theme, sheetContext,
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        color: AppColors.primary,
                        type: MessageType.image,
                        source: ImageSource.camera),
                    SizedBox(width: 12.w),
                    _attachOption(theme, sheetContext,
                        icon: Icons.videocam_rounded,
                        label: 'Record',
                        color: AppColors.teal,
                        type: MessageType.video,
                        source: ImageSource.camera),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachOption(
    ThemeData theme,
    BuildContext sheetContext, {
    required IconData icon,
    required String label,
    required Color color,
    required MessageType type,
    required ImageSource source,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(sheetContext);
          _pickAndSend(type, source);
        },
        child: Column(
          children: [
            Container(
              height: 56.r,
              width: 56.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.lg.r),
              ),
              child: Icon(icon, color: color, size: 26.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSend(MessageType type, ImageSource source) async {
    try {
      final isVideo = type == MessageType.video;
      final XFile? picked = isVideo
          ? await _picker.pickVideo(
              source: source,
              maxDuration: const Duration(minutes: 1),
            )
          : await _picker.pickImage(
              source: source,
              imageQuality: 70,
              maxWidth: 1600,
            );
      if (picked == null || !mounted) return;

      final file = File(picked.path);

      // Reject oversized attachments up front so the user gets a clear message
      // instead of an opaque permission-denied when the Storage rule rejects it.
      if (!isAcceptableChatMediaSize(await file.length())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Attachment is too large (max '
                '${kMaxChatMediaBytes ~/ (1024 * 1024)} MB).',
              ),
            ),
          );
        }
        return;
      }

      // Review step: preview the attachment and (optionally) caption it before
      // anything is uploaded. A null result means the user backed out.
      if (!mounted) return;
      final caption = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (_) => MediaPreviewScreen(file: file, isVideo: isVideo),
        ),
      );
      if (caption == null || !mounted) return;

      setState(() => _sendingMedia = true);
      await context.read<MessageProvider>().sendMediaMessage(
            widget.receiverId,
            file,
            type,
            caption: caption,
          );
      if (mounted) _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send attachment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _controller.text.trim();
    // Ignore empty text and re-entrancy (rapid double-tap / Enter + tap in the
    // same frame) so the same message can't be sent twice.
    if (text.isEmpty || _sending) return;

    // Capture before the await so we don't touch BuildContext across the gap.
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<MessageProvider>();

    _sending = true;
    // Optimistic clear keeps the input snappy; if the write fails we restore
    // the text and tell the user, so a message is never silently dropped.
    _controller.clear();
    _scrollToBottom();
    try {
      await provider.sendMessage(widget.receiverId, text);
    } catch (_) {
      if (mounted && _controller.text.isEmpty) _controller.text = text;
      messenger.showSnackBar(
        const SnackBar(content: Text('Message failed to send. Tap send to retry.')),
      );
    } finally {
      _sending = false;
    }
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
      // NOTE: name the sheet's own context `sheetContext`. Popping the sheet
      // deactivates that context, so it can't be reused to open the confirm
      // dialog — the dialog would silently fail and "delete" would do nothing.
      // Close the sheet with `sheetContext`, then drive the dialog off the
      // screen's still-mounted `context`.
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                height: 4.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person_outline,
                    color: theme.colorScheme.onSurface),
                title: Text('View Profile',
                    style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _viewProfile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete Conversation',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
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
        title: Text('Delete Chat',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to delete all messages?',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              // Capture everything off the context BEFORE the await — popping
              // the dialog deactivates dialogContext, and the screen may unmount.
              final messageProvider = context.read<MessageProvider>();
              final screenNavigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext); // close the confirm dialog now
              try {
                await messageProvider.deleteChat(widget.receiverId);
                if (mounted) screenNavigator.pop(); // leave the chat screen
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
