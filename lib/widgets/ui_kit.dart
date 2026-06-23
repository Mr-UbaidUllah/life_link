import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/widgets/motion.dart';

/// Bold-modern reusable building blocks shared across the redesigned app.
/// Keeping these in one place stops every screen reinventing cards, section
/// headers and badges.

/// Request urgency, ordered most → least critical. Drives badge color, label
/// and whether the badge pulses. (Wired to the data model in a later phase;
/// the design layer owns the visual mapping here.)
enum UrgencyLevel {
  critical,
  urgent,
  routine;

  /// Parse from a stored model string, defaulting to [UrgencyLevel.urgent].
  static UrgencyLevel fromName(String? name) => switch (name) {
        'critical' => UrgencyLevel.critical,
        'routine' => UrgencyLevel.routine,
        _ => UrgencyLevel.urgent,
      };

  String get label => switch (this) {
        UrgencyLevel.critical => 'Critical',
        UrgencyLevel.urgent => 'Urgent',
        UrgencyLevel.routine => 'Routine',
      };

  Color get color => switch (this) {
        UrgencyLevel.critical => AppColors.primary,
        UrgencyLevel.urgent => AppColors.amber,
        UrgencyLevel.routine => AppColors.green,
      };

  IconData get icon => switch (this) {
        UrgencyLevel.critical => Icons.priority_high_rounded,
        UrgencyLevel.urgent => Icons.access_time_filled_rounded,
        UrgencyLevel.routine => Icons.event_available_rounded,
      };

  bool get pulses => this == UrgencyLevel.critical;
}

/// A surface card with the app's large radius + hairline border, optional tap.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = AppRadii.xl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Container(
      padding: padding ?? EdgeInsets.all(AppSpace.lg.r),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius.r),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius.r),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Section title with an optional trailing action (e.g. "See all").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 18.sp),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  actionLabel!,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18.sp, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bold circular blood-type badge (e.g. "O+").
class BloodTypeBadge extends StatelessWidget {
  final String group;
  final double size;
  final bool filled;

  const BloodTypeBadge({
    super.key,
    required this.group,
    this.size = 48,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: size.r,
      width: size.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        group.isEmpty ? '?' : group,
        style: TextStyle(
          color: filled ? Colors.white : theme.colorScheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: (size * 0.32).sp,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Small status pill (open / urgent / available …).
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }
}

/// A compact stat tile (value + label) for impact/quick-glance rows.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpace.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(value,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22.sp)),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Bold-modern blood-request card used on Home and the Requests feed.
class RequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final bool matchesUser;
  final VoidCallback? onTap;

  /// Optional urgency — when set, a (pulsing, for critical) badge is shown.
  final UrgencyLevel? urgency;

  /// Optional distance from the viewer in km — shows a distance pill.
  final double? distanceKm;

  const RequestCard({
    super.key,
    required this.request,
    this.matchesUser = false,
    this.onTap,
    this.urgency,
    this.distanceKm,
  });

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpace.xl.w, 0, AppSpace.xl.w, AppSpace.md.h),
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.all(AppSpace.lg.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BloodTypeBadge(group: request.bloodGroup, size: 52),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title.isEmpty
                            ? '${request.bloodGroup} blood needed'
                            : request.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.sp),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, size: 13.sp, color: muted),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              request.hospital.isEmpty ? 'Unknown hospital' : request.hospital,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted, fontSize: 12.5.sp, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (urgency != null)
                  UrgencyBadge(level: urgency!)
                else
                  Icon(Icons.chevron_right_rounded, color: muted, size: 22.sp),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                if (matchesUser)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: const StatusPill(
                        label: 'For you', color: AppColors.primary, icon: Icons.favorite_rounded),
                  ),
                StatusPill(
                  label: '${request.bags} ${request.bags == 1 ? "bag" : "bags"}',
                  color: AppColors.info,
                  icon: Icons.water_drop_rounded,
                ),
                SizedBox(width: 8.w),
                if (distanceKm != null) ...[
                  DistancePill(km: distanceKm!),
                  SizedBox(width: 8.w),
                ],
                if ((request.city).isNotEmpty)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, size: 13.sp, color: muted),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(request.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted, fontSize: 12.sp, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                Text(_timeAgo(request.createdAt),
                    style: TextStyle(color: muted, fontSize: 11.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bold & vibrant building blocks (Phase 1 design system)
// ---------------------------------------------------------------------------

/// A vibrant gradient hero surface with a soft glow — the signature hero
/// container for Home, profile and CTAs. Falls back to a flat color if no
/// gradient is given.
class GradientHeroCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final bool glow;

  const GradientHeroCard({
    super.key,
    required this.child,
    this.gradient = AppGradients.hero,
    this.padding,
    this.margin,
    this.onTap,
    this.radius = AppRadii.xl,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = gradient is LinearGradient
        ? (gradient as LinearGradient).colors.first
        : AppColors.primary;
    final content = Container(
      padding: padding ?? EdgeInsets.all(AppSpace.xl.r),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius.r),
        boxShadow: glow ? AppGradients.glow(glowColor) : null,
      ),
      child: child,
    );
    final card = onTap == null
        ? content
        : TapScale(
            onTap: onTap,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius.r),
                onTap: onTap,
                child: content,
              ),
            ),
          );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}

/// Urgency badge. Pulses for [UrgencyLevel.critical] to grab attention.
/// Optionally renders a live countdown when [neededBy] is supplied.
class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel level;
  final DateTime? neededBy;

  const UrgencyBadge({super.key, required this.level, this.neededBy});

  String? _countdown() {
    if (neededBy == null) return null;
    final diff = neededBy!.difference(DateTime.now());
    if (diff.isNegative) return 'expired';
    if (diff.inHours < 1) return '${diff.inMinutes}m left';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }

  @override
  Widget build(BuildContext context) {
    final cd = _countdown();
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: level.color,
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
        boxShadow: level.pulses ? AppGradients.glow(level.color, alpha: 0.4) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            cd == null ? level.label : '${level.label} · $cd',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10.5.sp),
          ),
        ],
      ),
    );
    return Pulse(enabled: level.pulses, child: pill);
  }
}

/// Compact distance pill, e.g. "2.3 km". Formats sub-km as metres.
class DistancePill extends StatelessWidget {
  final double km;

  const DistancePill({super.key, required this.km});

  String get _label {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: _label,
      color: AppColors.teal,
      icon: Icons.near_me_rounded,
    );
  }
}

/// Donor availability toggle — a single, prominent control for "Available to
/// donate now". Vibrant when on, neutral when off.
class AvailabilityToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AvailabilityToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapScale(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.standard,
        padding: EdgeInsets.symmetric(horizontal: AppSpace.lg.w, vertical: AppSpace.md.h),
        decoration: BoxDecoration(
          gradient: value ? AppGradients.success : null,
          color: value ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.lg.r),
          border: value ? null : Border.all(color: theme.colorScheme.outline),
          boxShadow: value ? AppGradients.glow(AppColors.green, alpha: 0.3) : null,
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.bolt_rounded : Icons.bolt_outlined,
              color: value ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value ? 'Available to donate' : 'Not available',
                    style: TextStyle(
                      color: value ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                  Text(
                    value ? 'Donors nearby can reach you' : 'Tap to go on-call',
                    style: TextStyle(
                      color: value
                          ? Colors.white.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11.5.sp,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement / milestone chip for the donor profile (e.g. "🩸 5 donations").
class BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool earned;

  const BadgeChip({
    super.key,
    required this.label,
    required this.icon,
    this.color = AppColors.primary,
    this.earned = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = earned ? color : theme.colorScheme.onSurface.withValues(alpha: 0.3);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: c.withValues(alpha: earned ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
        border: Border.all(color: c.withValues(alpha: earned ? 0.3 : 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: c),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
                color: earned ? theme.colorScheme.onSurface : c,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

/// Like [StatTile] but the value counts up on first render (impact stats).
class AnimatedStatTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final String Function(int)? formatter;

  const AnimatedStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.all(AppSpace.lg.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          AnimatedCount(
            value: value,
            formatter: formatter,
            style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22.sp),
          ),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
