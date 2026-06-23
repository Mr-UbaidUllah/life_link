import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:blood_donation/widgets/motion.dart';

/// Flat stat tile used inside the "Our Impact" card on Home:
/// a bold accent-colored number over a muted label.
class ContributionCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  /// When set, the number counts up to this value on first render. [value] is
  /// used as a fallback (e.g. "—" while loading).
  final int? animatedValue;
  final String Function(int)? formatter;

  const ContributionCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.animatedValue,
    this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStyle = TextStyle(
      fontSize: 20.sp,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -0.5,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (animatedValue != null)
          AnimatedCount(
            value: animatedValue!,
            formatter: formatter,
            style: numberStyle,
          )
        else
          Text(value, style: numberStyle),
        SizedBox(height: 4.h),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
