import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:blood_donation/theme/theme.dart';

/// Consistent, theme-aware snackbars. Replaces the ad-hoc
/// `Colors.green`/`Colors.redAccent`/`Colors.orange` snackbars scattered across
/// screens (which were invisible or off-brand in dark mode).
enum _SnackKind { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackKind.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackKind.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackKind.info);

  static void _show(BuildContext context, String message, _SnackKind kind) {
    final (Color bg, IconData icon) = switch (kind) {
      _SnackKind.success => (AppColors.success, Icons.check_circle_rounded),
      _SnackKind.error => (AppColors.danger, Icons.error_rounded),
      _SnackKind.info => (AppColors.info, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
