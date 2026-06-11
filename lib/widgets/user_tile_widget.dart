import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UserTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;
  final String? subtitle; // last message or status

  /// Relative time of the last activity, shown top-right (e.g. "3h ago").
  final String? time;

  /// Unread message count; renders a badge bottom-right when > 0.
  final int unreadCount;

  /// Show the trailing chevron (used where the tile acts as a navigation row).
  final bool showChevron;

  /// Emphasise the subtitle (used for unread chats).
  final bool highlightSubtitle;

  /// Tighter typography for list contexts like the inbox.
  final bool dense;

  const UserTile({
    super.key,
    required this.name,
    this.imageUrl,
    this.onTap,
    this.subtitle,
    this.time,
    this.unreadCount = 0,
    this.showChevron = true,
    this.highlightSubtitle = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = dense ? 26.r : 28.r;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                /// PROFILE IMAGE
                _buildAvatar(theme, avatarRadius),

                SizedBox(width: 14.w),

                /// USER NAME & SUBTITLE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dense ? 15.5.sp : 18.sp,
                          fontWeight: dense ? FontWeight.w700 : FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: theme.colorScheme.onSurface.withValues(alpha: highlightSubtitle ? 0.85 : 0.5),
                            fontWeight: highlightSubtitle ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 10.w),
                _buildTrailing(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, double avatarRadius) {
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Icon(Icons.person_rounded, size: avatarRadius, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
          : null,
    );

    // In dense list contexts (the chat inbox) a plain avatar keeps the list
    // calm; the primary ring is reserved for single profile rows where it
    // reads as emphasis rather than noise.
    if (dense) return avatar;

    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: avatar,
    );
  }

  Widget _buildTrailing(ThemeData theme) {
    final hasMeta = time != null || unreadCount > 0;

    if (hasMeta) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (time != null)
            Text(
              time!,
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: unreadCount > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          if (unreadCount > 0) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
              constraints: BoxConstraints(minWidth: 20.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (showChevron) {
      return Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
      );
    }

    return const SizedBox.shrink();
  }
}
