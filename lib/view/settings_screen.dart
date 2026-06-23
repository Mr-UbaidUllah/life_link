import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/theme_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/delete_account_screen.dart';
import 'package:blood_donation/view/legal/legal_screens.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'profile/profile_details_screen.dart';

/// App Settings — rebuilt in the app's design system: a gradient identity
/// header, grouped cards with colored icon tiles, a real appearance selector
/// and a custom About sheet. Replaces the old shadowed-ListTile layout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
      }
    });
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
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
        ),
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<UserProvider>().loadCurrentUser(),
        color: theme.colorScheme.primary,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;
            if (userProvider.isLoading && user == null) {
              return const SettingsSkeleton();
            }
            if (user == null) {
              return RefreshableFill(
                child: Center(
                  child: Text(
                    'User not found.',
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16.sp),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _identityHeader(theme, user),
                SizedBox(height: 24.h),
                _groupLabel(theme, 'Profile'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    color: AppColors.primary,
                    title: 'Edit Profile Information',
                    subtitle: 'Name, photo, contact and bio',
                    onTap: () => _push(EditProfileScreen(user: user)),
                  ),
                ]),
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Appearance'),
                _appearanceCard(theme),
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Support & Info'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.info,
                    title: 'About Life Link',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAbout(theme),
                  ),
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.teal,
                    title: 'Help & FAQ',
                    subtitle: 'Answers to common questions',
                    onTap: () => _push(const FaqScreen()),
                  ),
                ]),
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Legal'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    color: AppColors.indigo,
                    title: 'Privacy Policy',
                    subtitle: 'How your data is collected and used',
                    onTap: () => _push(const PrivacyPolicyScreen()),
                  ),
                  _SettingsRow(
                    icon: Icons.gavel_rounded,
                    color: AppColors.plum,
                    title: 'Terms of Service',
                    subtitle: 'The rules for using Life Link',
                    onTap: () => _push(const TermsOfServiceScreen()),
                  ),
                ]),
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Account'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account and data',
                    onTap: () => _push(const DeleteAccountScreen()),
                  ),
                ]),
                SizedBox(height: 32.h),
                _logoutButton(theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------- Identity header

  Widget _identityHeader(ThemeData theme, UserModel user) {
    final hasImage =
        user.profileImage != null && user.profileImage!.isNotEmpty;
    return GradientHeroCard(
      padding: EdgeInsets.all(16.r),
      onTap: () => _push(ProfileDetailsScreen(userId: user.uid)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 30.r,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              backgroundImage: hasImage ? NetworkImage(user.profileImage!) : null,
              child: hasImage
                  ? null
                  : Icon(Icons.person_rounded, color: Colors.white, size: 30.r),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (user.name ?? '').trim().isEmpty ? 'Your Profile' : user.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2.h),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadii.pill.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined,
                          size: 12.sp, color: Colors.white),
                      SizedBox(width: 5.w),
                      Text('View public profile',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22.sp),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Appearance

  Widget _appearanceCard(ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        return AppCard(
          padding: EdgeInsets.all(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconChip(Icons.palette_outlined, AppColors.violet),
                  SizedBox(width: 12.w),
                  Text('Theme',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14.sp)),
                ],
              ),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(4.r),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadii.md.r),
                ),
                child: Row(
                  children: [
                    _themeOption(theme, 'Light', Icons.light_mode_rounded,
                        selected: !isDark,
                        onTap: () {
                      if (isDark) themeProvider.toggleTheme();
                    }),
                    _themeOption(theme, 'Dark', Icons.dark_mode_rounded,
                        selected: isDark,
                        onTap: () {
                      if (!isDark) themeProvider.toggleTheme();
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(ThemeData theme, String label, IconData icon,
      {required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm.r),
            border: selected
                ? Border.all(color: theme.colorScheme.outline)
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17.sp,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              SizedBox(width: 7.w),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Log out

  Widget _logoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(theme),
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: const Text('Log Out',
            style: TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Helpers

  Widget _groupLabel(ThemeData theme, String text) => Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );

  Widget _iconChip(IconData icon, Color color) => Container(
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.md.r),
        ),
        child: Icon(icon, size: 20.sp, color: color),
      );

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _confirmLogout(ThemeData theme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Log Out',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to log out from your account?',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
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
            child: const Text('Log Out',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    // Capture refs before the await so we don't touch a stale context after.
    final auth = context.read<AuthProviders>();
    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);
    await auth.logout();
    // Clear the cached profile so the next account that signs in on this device
    // can't briefly see the previous user's name/photo before its data loads.
    userProvider.clearUser();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showAbout(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 4.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(AppRadii.lg.r),
                boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.3),
              ),
              child: Icon(Icons.bloodtype_rounded,
                  size: 40.r, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text('Life Link',
                style: TextStyle(
                    fontSize: 20.sp, fontWeight: FontWeight.w900)),
            SizedBox(height: 4.h),
            Text('Version 1.0.0',
                style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            SizedBox(height: 16.h),
            Text(
              'Connecting blood donors with those in need — quickly, safely '
              'and close to home.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5.sp,
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            SizedBox(height: 20.h),
            Text('© 2026 Life Link',
                style: TextStyle(
                    fontSize: 11.5.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }

}

/// A titled group of settings rows rendered as a single bordered card with
/// hairline dividers between rows.
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
            height: 1,
            indent: 60.w,
            endIndent: 14.w,
            color: theme.colorScheme.outline));
      }
      rows.add(children[i]);
    }
    return AppCard(padding: EdgeInsets.zero, child: Column(children: rows));
  }
}

/// A single tappable settings row — colored icon chip, title, optional
/// subtitle and a trailing chevron.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.xl.r),
      child: Padding(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(9.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md.r),
              ),
              child: Icon(icon, size: 20.sp, color: color),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.sp)),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
