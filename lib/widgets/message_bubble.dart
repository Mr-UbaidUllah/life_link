import 'package:blood_donation/models/message_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/media_view_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// A single chat bubble.
///
/// Bubbles are *grouped*: a run of consecutive messages from the same sender
/// (within a short time window) reads as one stack. The caller computes the
/// [isFirstInGroup] / [isLastInGroup] flags; the bubble uses them to:
///   - merge the connecting corners so a group looks continuous,
///   - draw the speech "tail" only on the last bubble of the run,
///   - show the timestamp + delivery receipt only on the last bubble,
///   - reserve / fill the avatar gutter only beside the last received bubble.
///
/// Text, image and video messages are all rendered here.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  /// Avatar + name of the *other* participant — used to render the small
  /// gutter avatar beside received message groups.
  final String? peerImageUrl;
  final String peerName;

  const MessageBubble({
    super.key,
    required this.message,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.peerImageUrl,
    this.peerName = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
    final isMedia = message.isMedia;

    const tail = 5.0;
    const open = 20.0;
    const joint = 7.0; // tightened corner where bubbles connect in a group

    final radius = isMe
        ? BorderRadius.only(
            topLeft: Radius.circular(open.r),
            bottomLeft: Radius.circular(open.r),
            topRight: Radius.circular((isFirstInGroup ? open : joint).r),
            bottomRight: Radius.circular((isLastInGroup ? tail : joint).r),
          )
        : BorderRadius.only(
            topRight: Radius.circular(open.r),
            bottomRight: Radius.circular(open.r),
            topLeft: Radius.circular((isFirstInGroup ? open : joint).r),
            bottomLeft: Radius.circular((isLastInGroup ? tail : joint).r),
          );

    final bubble = Container(
      padding: isMedia
          ? EdgeInsets.all(4.r)
          : EdgeInsets.fromLTRB(14.w, 9.h, 14.w, 8.h),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * (isMedia ? 0.68 : 0.74),
      ),
      decoration: BoxDecoration(
        gradient: isMe ? AppGradients.hero : null,
        color: isMe ? null : theme.colorScheme.surface,
        borderRadius: radius,
        border: isMe ? null : Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: (isMe ? AppColors.primary : Colors.black)
                .withValues(alpha: isMe ? 0.18 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMedia
          ? _MediaContent(
              message: message,
              isMe: isMe,
              showMeta: isLastInGroup,
              innerRadius: radius,
            )
          : _TextContent(message: message, isMe: isMe, showMeta: isLastInGroup),
    );

    // Received messages reserve a left gutter for the peer avatar; the avatar
    // is only painted beside the last bubble of a received run.
    if (!isMe) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            12.w, isFirstInGroup ? 6.h : 1.5.h, 12.w, isLastInGroup ? 2.h : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _gutterAvatar(theme),
            SizedBox(width: 8.w),
            Flexible(child: bubble),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          12.w, isFirstInGroup ? 6.h : 1.5.h, 12.w, isLastInGroup ? 2.h : 0),
      child: Align(alignment: Alignment.centerRight, child: bubble),
    );
  }

  Widget _gutterAvatar(ThemeData theme) {
    final size = 28.r;
    if (!isLastInGroup) {
      // Keep the gutter width so the bubble column stays aligned.
      return SizedBox(width: size);
    }
    final hasImage = peerImageUrl != null && peerImageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: hasImage ? NetworkImage(peerImageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              peerName.isNotEmpty ? peerName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
    );
  }
}

/// Plain text body + (optional) meta row.
class _TextContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showMeta;

  const _TextContent({
    required this.message,
    required this.isMe,
    required this.showMeta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : theme.colorScheme.onSurface,
            fontSize: 14.5.sp,
            height: 1.32,
          ),
        ),
        if (showMeta) ...[
          SizedBox(height: 3.h),
          _MetaRow(message: message, isMe: isMe),
        ],
      ],
    );
  }
}

/// Image / video body. The media is clipped to the bubble shape, the time +
/// receipt float over the bottom-right corner, and an optional caption sits
/// below.
class _MediaContent extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showMeta;
  final BorderRadius innerRadius;

  const _MediaContent({
    required this.message,
    required this.isMe,
    required this.showMeta,
    required this.innerRadius,
  });

  bool get _isVideo => message.type == MessageType.video;

  void _open(BuildContext context) {
    final url = message.mediaUrl;
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MediaViewScreen(
          url: url,
          isVideo: _isVideo,
          heroTag: _isVideo ? null : url,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width * 0.62;
    final hasCaption = message.text.trim().isNotEmpty;

    // Shrink the media corners slightly so they nest inside the 4px frame.
    double corner(double base) => (base - 3).clamp(2.0, 40.0);
    final mediaRadius = BorderRadius.only(
      topLeft: Radius.circular(corner(innerRadius.topLeft.x)),
      topRight: Radius.circular(corner(innerRadius.topRight.x)),
      bottomLeft:
          Radius.circular(hasCaption ? 4 : corner(innerRadius.bottomLeft.x)),
      bottomRight:
          Radius.circular(hasCaption ? 4 : corner(innerRadius.bottomRight.x)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _open(context),
          child: ClipRRect(
            borderRadius: mediaRadius,
            child: Stack(
              children: [
                SizedBox(
                  width: width,
                  child: _isVideo
                      ? _VideoPreview(width: width)
                      : _ImagePreview(url: message.mediaUrl, width: width),
                ),
                if (showMeta)
                  Positioned(
                    right: 6.w,
                    bottom: 6.h,
                    child: _MetaOverlay(message: message, isMe: isMe),
                  ),
              ],
            ),
          ),
        ),
        if (hasCaption)
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 7.h, 10.w, 6.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 14.sp,
                    height: 1.3,
                  ),
                ),
                if (showMeta) ...[
                  SizedBox(height: 3.h),
                  _MetaRow(message: message, isMe: isMe),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? url;
  final double width;
  const _ImagePreview({required this.url, required this.width});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder(context, Icons.broken_image_rounded);
    }
    final image = Image.network(
      url!,
      width: width,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: width * 0.75,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) =>
          _placeholder(context, Icons.broken_image_rounded),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 320.h),
      child: Hero(tag: url!, child: image),
    );
  }

  Widget _placeholder(BuildContext context, IconData icon) {
    return Container(
      width: width,
      height: width * 0.7,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon,
          size: 40.sp,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.4)),
    );
  }
}

/// No frame is decoded for a video (keeps the list light) — show a branded
/// placeholder with a play button; the real player opens fullscreen on tap.
class _VideoPreview extends StatelessWidget {
  final double width;
  const _VideoPreview({required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * 0.66,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A2D36), Color(0xFF14171F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 34.sp),
          ),
          Positioned(
            left: 8.w,
            top: 8.h,
            child: Row(
              children: [
                Icon(Icons.videocam_rounded,
                    color: Colors.white.withValues(alpha: 0.9), size: 14.sp),
                SizedBox(width: 4.w),
                Text(
                  'Video',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Time + receipt floated over media (dark scrim pill for legibility).
class _MetaOverlay extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MetaOverlay({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.createdAt.toDate());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 4.w),
            Icon(
              message.isDelivered ? Icons.done_all_rounded : Icons.done_rounded,
              size: 13.sp,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}

/// Timestamp + (for my messages) a delivery receipt, shown on the last bubble
/// of a group.
class _MetaRow extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MetaRow({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('h:mm a').format(message.createdAt.toDate());
    final color = isMe
        ? Colors.white.withValues(alpha: 0.85)
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        if (isMe) ...[
          SizedBox(width: 4.w),
          Icon(
            message.isDelivered ? Icons.done_all_rounded : Icons.done_rounded,
            size: 13.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
  }
}
