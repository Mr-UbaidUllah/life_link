import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// "Just now", "5m ago", "3h ago", "2d ago", then "14 Jun".
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(time.toLocal());
}

class HomeHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const HomeHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(Icons.chevron_right_rounded, size: 16.sp, color: theme.colorScheme.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Blood request card used on Home, Requests, Search and Profile screens.
class HomeContainer extends StatelessWidget {
  const HomeContainer({
    super.key,
    required this.request,
    this.matchesUser = false,
    this.onTap,
  });

  final BloodRequestModel request;
  final bool matchesUser;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMine = request.userId.isNotEmpty && currentUserId == request.userId;
    final accent = isMine ? AppColors.blue : theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final isCritical = !isMine && request.expiryDate.difference(DateTime.now()).inHours < 24;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _BloodBadge(group: request.bloodGroup, accent: accent),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (isMine)
                            const _Tag(label: 'Yours', color: AppColors.blue)
                          else if (matchesUser)
                            const _Tag(
                              label: 'Matches you',
                              color: AppColors.green,
                              icon: Icons.check_circle_rounded,
                            ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              request.city.isNotEmpty ? '${request.hospital} · ${request.city}' : request.hospital,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5.sp, color: muted),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 7.h),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                          SizedBox(width: 5.w),
                          Text(
                            request.bags > 0
                                ? '${relativeTime(request.createdAt)} · ${request.bags} ${request.bags == 1 ? 'bag' : 'bags'}'
                                : relativeTime(request.createdAt),
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          _StatusChip(
                            label: isMine ? 'Manage' : (isCritical ? 'Critical' : 'Urgent'),
                            color: accent,
                            filled: isCritical,
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

class _BloodBadge extends StatelessWidget {
  const _BloodBadge({required this.group, required this.accent});

  final String group;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 62.h,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop_rounded, size: 15.sp, color: accent),
          SizedBox(height: 2.h),
          Text(
            group,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: accent),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 6.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 3.w),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 9.5.sp, color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5.sp,
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Compact quick-action tile shown in a single row on Home.
class ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const ActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54.r,
                height: 54.r,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(icon, size: 25.sp, color: accent),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11.sp,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
