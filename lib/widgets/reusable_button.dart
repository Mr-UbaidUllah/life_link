import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Primary action button used across auth/profile/forms.
///
/// Supports a loading spinner and a disabled state so screens stop hand-rolling
/// their own `isLoading ? CircularProgressIndicator() : button` ternaries.
/// Backwards compatible: existing `ReusableButton(label: '…')` call sites that
/// wrap it in their own tap handler keep working when [onPressed] is null.
class ReusableButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  const ReusableButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool interactive = enabled && !isLoading;
    final Color background = interactive
        ? theme.colorScheme.primary
        : theme.colorScheme.primary.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      enabled: interactive,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(15.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: interactive ? onPressed : null,
          child: SizedBox(
            height: 55.h,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      height: 24.h,
                      width: 24.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
