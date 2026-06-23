import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

/// Theme-aware wrapper that applies the shimmer sweep to its [child].
///
/// Build skeleton layouts out of plain white [Bone]s and wrap them in this –
/// the gradient animation is handled here so individual placeholders stay dumb.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: child,
    );
  }
}

/// A single rounded placeholder block. Must live inside an [AppShimmer].
class Bone extends StatelessWidget {
  const Bone({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius.r),
      ),
    );
  }
}

/// Repeats [itemBuilder] inside a single shimmer sweep. Use as a drop-in for a
/// list's loading state so every card placeholder animates in unison.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.padding,
    this.separator,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final double? separator;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ?? EdgeInsets.all(20.w),
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: separator ?? 0),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Two stacked lines – a name and a shorter subtitle.
class UserNameShimmer extends StatelessWidget {
  const UserNameShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          Bone(height: 20.h, width: 150.w, radius: 6),
          SizedBox(height: 8.h),
          Bone(height: 14.h, width: 100.w, radius: 6),
        ],
      ),
    );
  }
}

/// Skeleton matching [HomeContainer] – blood badge + title/location/time rows.
class BloodRequestSkeleton extends StatelessWidget {
  const BloodRequestSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Bone(width: 52.w, height: 62.h, radius: 14),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: 14.h, width: 160.w, radius: 6),
                SizedBox(height: 10.h),
                Bone(height: 11.h, width: 120.w, radius: 5),
                SizedBox(height: 9.h),
                Row(
                  children: [
                    Bone(height: 10.h, width: 70.w, radius: 5),
                    const Spacer(),
                    Bone(height: 18.h, width: 56.w, radius: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the [AmbulenceCard] / [OrganizationCard] layout (accent bar +
/// square image + text rows + trailing action button).
class ContactCardSkeleton extends StatelessWidget {
  const ContactCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Bone(width: 6.w, height: 94.h, radius: 0),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Bone(width: 70.w, height: 70.w, radius: 16),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Bone(height: 15.h, width: 130.w, radius: 6),
                            SizedBox(height: 10.h),
                            Bone(height: 11.h, width: 150.w, radius: 5),
                            SizedBox(height: 7.h),
                            Bone(height: 11.h, width: 90.w, radius: 5),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Bone(width: 38.r, height: 38.r, shape: BoxShape.circle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the [VolunteerCard] layout (square image + name + description).
class VolunteerCardSkeleton extends StatelessWidget {
  const VolunteerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Bone(width: 65.w, height: 65.w, radius: 16),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: 15.h, width: 120.w, radius: 6),
                SizedBox(height: 10.h),
                Bone(height: 11.h, width: double.infinity, radius: 5),
                SizedBox(height: 6.h),
                Bone(height: 11.h, width: 140.w, radius: 5),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Bone(width: 38.r, height: 38.r, shape: BoxShape.circle),
        ],
      ),
    );
  }
}

/// Skeleton for the [UserTile] layout (avatar + name + subtitle + trailing).
class UserTileSkeleton extends StatelessWidget {
  const UserTileSkeleton({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarRadius = dense ? 26.r : 28.r;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Bone(width: avatarRadius * 2, height: avatarRadius * 2, shape: BoxShape.circle),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone(height: dense ? 13.h : 15.h, width: 130.w, radius: 6),
                SizedBox(height: 8.h),
                Bone(height: 11.h, width: 180.w, radius: 5),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Bone(height: 10.h, width: 30.w, radius: 5),
        ],
      ),
    );
  }
}

/// Skeleton matching the notification inbox cards (icon tile + title + body +
/// meta row). Drop in while the notifications stream is still connecting.
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: EdgeInsets.symmetric(vertical: 4.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone(width: 42.r, height: 42.r, radius: 14),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Bone(height: 14.h, width: 150.w, radius: 6),
                    SizedBox(height: 9.h),
                    Bone(height: 11.h, width: double.infinity, radius: 5),
                    SizedBox(height: 6.h),
                    Bone(height: 11.h, width: 170.w, radius: 5),
                    SizedBox(height: 10.h),
                    Bone(height: 10.h, width: 100.w, radius: 5),
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

/// One generic "menu row" placeholder: leading icon tile + label + trailing.
class _RowBone extends StatelessWidget {
  const _RowBone();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          Bone(width: 38.r, height: 38.r, radius: 12),
          SizedBox(width: 14.w),
          Expanded(child: Bone(height: 13.h, width: 120.w, radius: 6)),
          SizedBox(width: 12.w),
          Bone(height: 14.h, width: 14.w, radius: 5),
        ],
      ),
    );
  }
}

Widget _cardBox(BuildContext context, Widget child) {
  final theme = Theme.of(context);
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(24.r),
      border: Border.all(color: theme.colorScheme.outline),
    ),
    child: child,
  );
}

/// Skeleton for the profile / "More" hub – a header (avatar + name + stats)
/// followed by grouped menu rows.
class ProfileMenuSkeleton extends StatelessWidget {
  const ProfileMenuSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
        child: Column(
          children: [
            Bone(width: 88.r, height: 88.r, shape: BoxShape.circle),
            SizedBox(height: 14.h),
            Bone(height: 18.h, width: 160.w, radius: 6),
            SizedBox(height: 8.h),
            Bone(height: 12.h, width: 120.w, radius: 6),
            SizedBox(height: 22.h),
            _cardBox(
              context,
              Column(children: const [_RowBone(), _RowBone(), _RowBone()]),
            ),
            SizedBox(height: 16.h),
            _cardBox(
              context,
              Column(children: const [_RowBone(), _RowBone(), _RowBone(), _RowBone()]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for grouped settings lists – a few cards of menu rows.
class SettingsSkeleton extends StatelessWidget {
  const SettingsSkeleton({super.key, this.sections = 3, this.rowsPerSection = 3});

  final int sections;
  final int rowsPerSection;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var s = 0; s < sections; s++) ...[
              Padding(
                padding: EdgeInsets.only(left: 4.w, bottom: 10.h, top: s == 0 ? 0 : 8.h),
                child: Bone(height: 11.h, width: 90.w, radius: 5),
              ),
              _cardBox(
                context,
                Column(
                  children: [
                    for (var r = 0; r < rowsPerSection; r++) const _RowBone(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a chat thread – alternating left/right message bubbles.
class MessageListSkeleton extends StatelessWidget {
  const MessageListSkeleton({super.key, this.itemCount = 8});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final mine = index.isOdd;
          // Vary the bubble width so the thread reads as a real conversation.
          final width = (index % 3 == 0) ? 220.w : (index % 3 == 1 ? 140.w : 180.w);
          return Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              child: Bone(width: width, height: 40.h, radius: 16),
            ),
          );
        },
      ),
    );
  }
}
