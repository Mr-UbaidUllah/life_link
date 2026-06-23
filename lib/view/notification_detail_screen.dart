import 'package:blood_donation/models/notification_model.dart';
import 'package:blood_donation/services/blood_request_service.dart';
import 'package:blood_donation/services/notification_database_service.dart';
import 'package:blood_donation/services/user_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Visual identity (icon, accent colour, human label) for a notification type.
/// Shared between the inbox list and this detail screen so a `chat` always
/// looks the same in both places.
class NotificationVisual {
  final IconData icon;
  final Color color;
  final String label;
  const NotificationVisual(this.icon, this.color, this.label);

  static NotificationVisual of(String type) {
    switch (type) {
      case 'chat':
        return const NotificationVisual(
            Icons.chat_bubble_rounded, AppColors.info, 'Message');
      case 'blood_request':
        return const NotificationVisual(
            Icons.water_drop_rounded, AppColors.primary, 'Blood request');
      case 'donor_available':
        return const NotificationVisual(Icons.volunteer_activism_rounded,
            AppColors.success, 'Donor available');
      case 're_eligible':
        return const NotificationVisual(
            Icons.favorite_rounded, AppColors.coral, 'Eligibility');
      default:
        return const NotificationVisual(
            Icons.notifications_rounded, AppColors.indigo, 'Update');
    }
  }
}

/// Full-screen view of a single notification. Marks the notification read on
/// open and offers a contextual action (open the chat, view the linked blood
/// request, message the donor) based on [NotificationModel.type].
class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final _notifications = NotificationDatabaseService();
  final _requests = BloodRequestService();
  final _users = UserFirestoreService();

  bool _actionBusy = false;

  NotificationModel get _n => widget.notification;

  @override
  void initState() {
    super.initState();
    // Opening the detail counts as reading it.
    if (!_n.isRead) _notifications.markAsRead(_n.id);
  }

  Future<void> _openChat() async {
    if (_actionBusy) return;
    final id = _n.senderId;
    if (id == null || id.isEmpty) return;

    // `chat` notifications carry the sender's name as the title; for other
    // types we look the user up so the chat header isn't blank.
    setState(() => _actionBusy = true);
    String name = _n.type == 'chat' ? _n.title : '';
    String? image;
    if (name.isEmpty) {
      final user = await _users.fetchUserById(id);
      name = user?.name ?? 'User';
      image = user?.profileImage;
    }
    if (!mounted) return;
    setState(() => _actionBusy = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(name: name, imageUrl: image, receiverId: id),
      ),
    );
  }

  Future<void> _openRequest() async {
    if (_actionBusy) return;
    final id = _n.requestId;
    if (id == null || id.isEmpty) return;

    setState(() => _actionBusy = true);
    final request = await _requests.getRequestById(id);
    if (!mounted) return;
    setState(() => _actionBusy = false);

    if (request == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This request is no longer available.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailsScreen(request: request)),
    );
  }

  void _openProfile() {
    final id = _n.senderId;
    if (id == null || id.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileDetailsScreen(userId: id)),
    );
  }

  Future<void> _delete() async {
    await _notifications.deleteNotification(_n.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = NotificationVisual.of(_n.type);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notification', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _delete,
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.error, size: 22.sp),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
        children: [
          _Hero(visual: visual),
          SizedBox(height: 24.h),
          Text(
            _n.title.isEmpty ? 'Notification' : _n.title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 14.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
              SizedBox(width: 6.w),
              Text(
                DateFormat('EEEE, d MMM • h:mm a')
                    .format(_n.createdAt.toLocal()),
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg.r),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Text(
              _n.body.isEmpty ? 'No additional details.' : _n.body,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          SizedBox(height: 28.h),
          ..._buildActions(theme, visual),
        ],
      ),
    );
  }

  List<Widget> _buildActions(ThemeData theme, NotificationVisual visual) {
    final spinner = SizedBox(
      width: 20.w,
      height: 20.w,
      child: const CircularProgressIndicator(
          strokeWidth: 2.4, color: Colors.white),
    );

    switch (_n.type) {
      case 'chat':
        if ((_n.senderId ?? '').isEmpty) return const [];
        return [
          FilledButton.icon(
            onPressed: _actionBusy ? null : _openChat,
            icon: _actionBusy
                ? spinner
                : const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Open chat'),
          ),
        ];
      case 'blood_request':
        if ((_n.requestId ?? '').isEmpty) return const [];
        return [
          FilledButton.icon(
            onPressed: _actionBusy ? null : _openRequest,
            icon: _actionBusy
                ? spinner
                : const Icon(Icons.visibility_outlined),
            label: const Text('View request'),
          ),
        ];
      case 'donor_available':
        if ((_n.senderId ?? '').isEmpty) return const [];
        return [
          FilledButton.icon(
            onPressed: _actionBusy ? null : _openChat,
            icon: _actionBusy
                ? spinner
                : const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message donor'),
          ),
          SizedBox(height: 12.h),
          OutlinedButton.icon(
            onPressed: _actionBusy ? null : _openProfile,
            icon: const Icon(Icons.person_outline_rounded),
            label: const Text('View profile'),
          ),
        ];
      default:
        return const [];
    }
  }
}

class _Hero extends StatelessWidget {
  final NotificationVisual visual;
  const _Hero({required this.visual});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
          ),
          child: Icon(visual.icon, size: 30.sp, color: visual.color),
        ),
        SizedBox(width: 14.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: visual.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.pill.r),
          ),
          child: Text(
            visual.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: visual.color,
            ),
          ),
        ),
      ],
    );
  }
}
