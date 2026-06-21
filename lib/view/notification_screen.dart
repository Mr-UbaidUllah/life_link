import 'package:blood_donation/models/notification_model.dart';
import 'package:blood_donation/services/notification_database_service.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// In-app notification inbox. Reads the current user's
/// `users/{uid}/notifications` subcollection (written by chat messages, blood
/// request matches, etc.), lets them tap to mark read, swipe to delete, and
/// clear all at once.
class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final NotificationDatabaseService _service = NotificationDatabaseService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _service.getNotifications(),
            builder: (context, snapshot) {
              final hasItems = (snapshot.data?.isNotEmpty) ?? false;
              if (!hasItems) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClearAll(context, theme),
                child: Text(
                  'Clear all',
                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 13.sp),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Notifications stream live from Firestore, so they're already
          // current — the pull just gives the user explicit feedback.
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        color: theme.colorScheme.primary,
        child: StreamBuilder<List<NotificationModel>>(
        stream: _service.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? const <NotificationModel>[];
          if (notifications.isEmpty) {
            return RefreshableFill(child: _buildEmptyState(theme));
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  color: theme.colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _service.deleteNotification(n.id),
                child: _NotificationTile(
                  notification: n,
                  onTap: () {
                    if (!n.isRead) _service.markAsRead(n.id);
                  },
                ),
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
              Icons.notifications_none_rounded,
              size: 44.sp,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Updates about messages and blood\nrequests will show up here.',
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

  void _confirmClearAll(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Clear notifications', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Remove all notifications? This cannot be undone.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              _service.clearAll();
              Navigator.pop(dialogContext);
            },
            child: Text('Clear all', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  IconData _iconFor(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'blood_request':
        return Icons.water_drop_rounded;
      case 'donor_available':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? theme.colorScheme.primary.withValues(alpha: 0.04) : null,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(notification.type), size: 18.sp, color: theme.colorScheme.primary),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title.isEmpty ? 'Notification' : notification.title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    relativeTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: EdgeInsets.only(top: 4.h, left: 8.w),
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
