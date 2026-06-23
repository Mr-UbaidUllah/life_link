import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/widgets/app_snackbar.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// In-app account deletion — required for Play Store / App Store compliance.
///
/// Spells out exactly what is removed, requires the user to re-enter their
/// password (Firebase needs a recent login to delete), and only deletes after
/// an explicit final confirmation.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      AppSnackbar.error(context, 'Enter your password to continue.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text('Delete account?',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text(
            'This permanently deletes your profile, your blood requests and your '
            'notifications. This cannot be undone.',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete forever',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final auth = context.read<AuthProviders>();
    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);

    try {
      await auth.deleteAccount(password);
      userProvider.clearUser();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text('Delete Account', style: theme.textTheme.titleLarge),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        children: Stagger.children([
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.xl.r),
              border:
                  Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 28.sp),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    'Deleting your account is permanent and cannot be undone.',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                        height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Text('What gets deleted',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.sp)),
          SizedBox(height: 12.h),
          _bullet(theme, Icons.person_outline_rounded,
              'Your profile and account details'),
          _bullet(theme, Icons.bloodtype_outlined,
              'All blood requests you created'),
          _bullet(theme, Icons.notifications_none_rounded,
              'Your notifications'),
          _bullet(theme, Icons.health_and_safety_outlined,
              'Your health and donor information'),
          SizedBox(height: 24.h),
          Text('Confirm your password',
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 15.sp)),
          SizedBox(height: 6.h),
          Text('For your security, please re-enter your password to continue.',
              style: TextStyle(
                  fontSize: 12.5.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
          SizedBox(height: 12.h),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ),
          SizedBox(height: 28.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _confirmAndDelete,
              icon: _busy
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Icon(Icons.delete_forever_rounded),
              label: Text(_busy ? 'Deleting…' : 'Delete my account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ], step: const Duration(milliseconds: 45)),
      ),
    );
  }

  Widget _bullet(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon,
              size: 20.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5.sp,
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.8))),
          ),
        ],
      ),
    );
  }
}
