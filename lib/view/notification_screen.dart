import 'package:blood_donation/models/notification_model.dart';
import 'package:blood_donation/services/notification_database_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/notification_detail_screen.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// In-app notification inbox. Reads the current user's
/// `users/{uid}/notifications` subcollection (written by chat messages, blood
/// request matches, etc.). Notifications are grouped by recency (Today /
/// Yesterday / Earlier); tap opens the full detail screen, swipe deletes, and
/// the header offers mark-all-read + clear-all.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationDatabaseService _service = NotificationDatabaseService();

  // Cache the stream ONCE so the AppBar actions and the body share a single
  // Firestore listener (instead of opening two), and a parent rebuild doesn't
  // hand the StreamBuilders a new stream identity and re-flash the skeleton.
  late final Stream<List<NotificationModel>> _stream =
      _service.getNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 20.sp),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 0 : 20.w,
        title: Text('Notifications', style: theme.textTheme.titleLarge),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _stream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <NotificationModel>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    color: theme.colorScheme.onSurface),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md.r)),
                onSelected: (value) {
                  if (value == 'read') _service.markAllAsRead();
                  if (value == 'clear') _confirmClearAll(context, theme);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'read',
                    enabled: items.any((n) => !n.isRead),
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded,
                            size: 18.sp, color: theme.colorScheme.primary),
                        SizedBox(width: 10.w),
                        const Text('Mark all read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_rounded,
                            size: 18.sp, color: theme.colorScheme.error),
                        SizedBox(width: 10.w),
                        const Text('Clear all'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(width: 4.w),
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
            // Crossfade between the skeleton, the empty state and the live
            // list so the screen never "snaps" between loading phases.
            final Widget content;

            if (snapshot.connectionState == ConnectionState.waiting) {
              content = const NotificationListSkeleton(key: ValueKey('loading'));
            } else {
              final notifications =
                  snapshot.data ?? const <NotificationModel>[];
              if (notifications.isEmpty) {
                content = RefreshableFill(
                    key: const ValueKey('empty'), child: _EmptyState());
              } else {
                final unread =
                    notifications.where((n) => !n.isRead).length;
                final sections = _groupByRecency(notifications);

                // Build the rows, then stagger their entrance so they cascade
                // in after the skeleton fades out.
                final rows = <Widget>[
                  if (unread > 0) _UnreadBanner(count: unread),
                  for (final section in sections) ...[
                    _SectionHeader(label: section.label),
                    for (final n in section.items)
                      Dismissible(
                        key: Key(n.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          margin: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
                          padding: EdgeInsets.symmetric(horizontal: 22.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(AppRadii.lg.r),
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _service.deleteNotification(n.id),
                        child: _NotificationCard(
                          notification: n,
                          onTap: () {
                            if (!n.isRead) _service.markAsRead(n.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NotificationDetailScreen(notification: n),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ];

                content = ListView(
                  key: const ValueKey('list'),
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.only(bottom: 24.h),
                  children: rows,
                );
              }
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: AppMotion.standard,
              switchOutCurve: AppMotion.standard,
              child: content,
            );
          },
        ),
      ),
    );
  }

  /// Splits the (already date-descending) list into Today / Yesterday / Earlier
  /// buckets, dropping any that are empty.
  List<_Section> _groupByRecency(List<NotificationModel> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <NotificationModel>[];
    final yesterdayItems = <NotificationModel>[];
    final earlierItems = <NotificationModel>[];

    for (final n in items) {
      final d = n.createdAt.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) {
        todayItems.add(n);
      } else if (day == yesterday) {
        yesterdayItems.add(n);
      } else {
        earlierItems.add(n);
      }
    }

    return [
      if (todayItems.isNotEmpty) _Section('Today', todayItems),
      if (yesterdayItems.isNotEmpty) _Section('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) _Section('Earlier', earlierItems),
    ];
  }

  void _confirmClearAll(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Clear notifications',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'Remove all notifications? This cannot be undone.',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () {
              _service.clearAll();
              Navigator.pop(dialogContext);
            },
            child: Text('Clear all',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String label;
  final List<NotificationModel> items;
  const _Section(this.label, this.items);
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 8.h),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _UnreadBanner extends StatelessWidget {
  final int count;
  const _UnreadBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.25),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              count == 1
                  ? '1 new notification'
                  : '$count new notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.isRead;
    final visual = NotificationVisual.of(notification.type);

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 4.h),
      child: Material(
        color: unread
            ? visual.color.withValues(alpha: 0.06)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg.r),
          child: Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg.r),
              border: Border.all(
                color: unread
                    ? visual.color.withValues(alpha: 0.25)
                    : theme.colorScheme.outline,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(11.r),
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md.r),
                  ),
                  child:
                      Icon(visual.icon, size: 20.sp, color: visual.color),
                ),
                SizedBox(width: 13.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title.isEmpty
                                  ? 'Notification'
                                  : notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5.sp,
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              margin: EdgeInsets.only(left: 8.w, top: 2.h),
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: visual.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.35,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Text(
                            visual.label,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: visual.color,
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          Text(
                            relativeTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 46.sp,
              color: theme.colorScheme.primary.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
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
}
