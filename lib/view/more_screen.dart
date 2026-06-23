import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/theme_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/utils/donation_eligibility.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/delete_account_screen.dart';
import 'package:blood_donation/view/edit_profile_screen.dart';
import 'package:blood_donation/view/legal/legal_screens.dart';
import 'package:blood_donation/view/organization_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/view/volunteer_screen.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// A donor "rank" earned by completing donations — drives the donor-status card.
class _DonorTier {
  final int at;
  final String name;
  final IconData icon;
  const _DonorTier(this.at, this.name, this.icon);

  static const List<_DonorTier> ladder = [
    _DonorTier(0, 'New Donor', Icons.person_rounded),
    _DonorTier(1, 'First Drop', Icons.water_drop_rounded),
    _DonorTier(3, 'Regular', Icons.repeat_rounded),
    _DonorTier(5, 'Lifesaver', Icons.favorite_rounded),
    _DonorTier(10, 'Hero', Icons.shield_rounded),
    _DonorTier(25, 'Legend', Icons.workspace_premium_rounded),
  ];

  /// The (current, next) tiers for [count] donations. `next` is null at the top.
  static (_DonorTier, _DonorTier?) forCount(int count) {
    var current = ladder.first;
    for (final t in ladder) {
      if (count >= t.at) current = t;
    }
    final idx = ladder.indexOf(current);
    final next = idx + 1 < ladder.length ? ladder[idx + 1] : null;
    return (current, next);
  }
}

/// The Settings tab — the app's account & preferences hub.
///
/// All profile/donor information lives together under the "Profile" heading; the
/// remaining headings are pure settings (Services, Appearance, Support, Legal
/// and a danger zone). Messaging is its own tab, so there is no inbox entry.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<UserProvider>().loadCurrentUser();
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
        automaticallyImplyLeading: false,
        titleSpacing: 20.w,
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final user = userProvider.user;
          if (user == null) {
            return const ProfileMenuSkeleton();
          }
          return RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => context.read<UserProvider>().loadCurrentUser(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 110.h),
              children: [
                // ---- PROFILE: everything about the user lives here ----
                _groupLabel(theme, 'Profile'),
                _profileCard(theme, user),
                SizedBox(height: 12.h),
                user.isDonor
                    ? _buildDonorCard(theme, user)
                    : _buildBecomeDonorCard(theme),
                if (user.isDonor) ...[
                  SizedBox(height: 12.h),
                  _buildAvailability(),
                  SizedBox(height: 12.h),
                  _buildEligibility(theme, user),
                ],
                SizedBox(height: 12.h),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    color: AppColors.primary,
                    title: 'Edit Profile',
                    subtitle: 'Name, photo, contact and bio',
                    onTap: () => _openEdit(user),
                  ),
                  _SettingsRow(
                    icon: Icons.badge_outlined,
                    color: AppColors.blue,
                    title: 'View Public Profile',
                    subtitle: 'How others see you',
                    onTap: () =>
                        _push(ProfileDetailsScreen(userId: user.uid)),
                  ),
                  _SettingsRow(
                    icon: Icons.history_rounded,
                    color: AppColors.plum,
                    title: 'My Requests',
                    subtitle: 'Requests you have posted',
                    onTap: () => _push(const _MyRequestsRedirect()),
                  ),
                ]),

                // ---- SERVICES ----
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Services'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.business_rounded,
                    color: AppColors.indigo,
                    title: 'Partner Organizations',
                    onTap: () => _push(const OrganizationScreen()),
                  ),
                  _SettingsRow(
                    icon: Icons.airport_shuttle_rounded,
                    color: AppColors.primary,
                    title: 'Ambulance Services',
                    onTap: () => _push(const AmbulanceScreen()),
                  ),
                  _SettingsRow(
                    icon: Icons.group_add_rounded,
                    color: AppColors.teal,
                    title: 'Volunteers',
                    onTap: () => _push(const VolunteerScreen()),
                  ),
                ]),

                // ---- APPEARANCE ----
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Appearance'),
                _appearanceCard(theme),

                // ---- SUPPORT ----
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Support'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.teal,
                    title: 'Help & FAQ',
                    subtitle: 'Answers to common questions',
                    onTap: () => _push(const FaqScreen()),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.info,
                    title: 'About Life Link',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAbout(theme),
                  ),
                ]),

                // ---- LEGAL ----
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Legal'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.shield_outlined,
                    color: AppColors.indigo,
                    title: 'Privacy Policy',
                    onTap: () => _push(const PrivacyPolicyScreen()),
                  ),
                  _SettingsRow(
                    icon: Icons.gavel_rounded,
                    color: AppColors.plum,
                    title: 'Terms of Service',
                    onTap: () => _push(const TermsOfServiceScreen()),
                  ),
                ]),

                // ---- ACCOUNT ACTIONS ----
                SizedBox(height: 22.h),
                _groupLabel(theme, 'Account'),
                _SettingsGroup(children: [
                  _SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account',
                    onTap: () => _push(const DeleteAccountScreen()),
                  ),
                ]),
                SizedBox(height: 16.h),
                _buildSignOut(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------- Profile card

  Widget _profileCard(ThemeData theme, UserModel user) {
    final hasImage =
        user.profileImage != null && user.profileImage!.isNotEmpty;
    final name = (user.name ?? '').trim();
    final displayName = name.isEmpty ? 'Your Profile' : name;
    final location = [
      if ((user.city ?? '').trim().isNotEmpty) user.city!.trim(),
      if ((user.country ?? '').trim().isNotEmpty) user.country!.trim(),
    ].join(', ');

    return GradientHeroCard(
      padding: EdgeInsets.all(16.r),
      onTap: () => _push(ProfileDetailsScreen(userId: user.uid)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 32.r,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage:
                      hasImage ? NetworkImage(user.profileImage!) : null,
                  child: hasImage
                      ? null
                      : Icon(Icons.person_rounded,
                          color: Colors.white, size: 32.r),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3)),
                    if (user.email.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 22.sp),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 6.h,
                children: [
                  if ((user.bloodGroup ?? '').isNotEmpty)
                    _pill(Icons.water_drop_rounded, user.bloodGroup!),
                  _pill(
                      user.isDonor
                          ? Icons.verified_rounded
                          : Icons.person_outline_rounded,
                      user.isDonor ? 'Donor' : 'Member'),
                  if (location.isNotEmpty)
                    _pill(Icons.location_on_rounded, location),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Donor status card

  Widget _buildDonorCard(ThemeData theme, UserModel user) {
    final (current, next) = _DonorTier.forCount(user.donationCount);
    final lives = user.donationCount * 3;
    final remaining = next == null ? 0 : next.at - user.donationCount;

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: AppGradients.urgent,
                  borderRadius: BorderRadius.circular(AppRadii.md.r),
                ),
                child: Icon(current.icon, color: Colors.white, size: 24.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${current.name} · Level ${_DonorTier.ladder.indexOf(current) + 1}',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15.sp)),
                    SizedBox(height: 2.h),
                    Text(
                      next == null
                          ? 'Top tier reached — you are a legend!'
                          : '$remaining more to reach ${next.name}',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _levelStat(theme, lives, 'Lives Saved', AppColors.primary),
              _statDivider(theme),
              _levelStat(
                  theme, user.donationCount, 'Donations', AppColors.green),
              _statDivider(theme),
              _levelStat(theme, user.createdAt.year, 'Since', AppColors.blue,
                  animate: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelStat(ThemeData theme, int value, String label, Color color,
      {bool animate = true}) {
    final numberStyle = TextStyle(
        fontSize: 21.sp,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -0.5);
    return Expanded(
      child: Column(
        children: [
          animate
              ? AnimatedCount(value: value, style: numberStyle)
              : Text('$value', style: numberStyle),
          SizedBox(height: 3.h),
          Text(label,
              style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
        ],
      ),
    );
  }

  Widget _statDivider(ThemeData theme) =>
      Container(height: 32.h, width: 1, color: theme.colorScheme.outline);

  Widget _buildBecomeDonorCard(ThemeData theme) {
    return GradientHeroCard(
      gradient: AppGradients.success,
      padding: EdgeInsets.all(16.r),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const UserDonateBlood())),
      child: Row(
        children: [
          Icon(Icons.volunteer_activism_rounded,
              color: Colors.white, size: 30.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Become a donor',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp)),
                SizedBox(height: 3.h),
                Text('One donation can save up to three lives.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5.sp)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 24.sp),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Availability

  Widget _buildAvailability() {
    return Consumer<UserProvider>(
      builder: (context, p, _) => AvailabilityToggle(
        value: p.user?.isAvailable ?? false,
        onChanged: (v) => context.read<UserProvider>().setAvailability(v),
      ),
    );
  }

  // ------------------------------------------------------------- Eligibility

  Widget _buildEligibility(ThemeData theme, UserModel user) {
    final result = user.evaluateEligibility();
    final next = user.nextEligibleDate;
    final inCooldown = next != null && next.isAfter(DateTime.now());

    final (Color accent, IconData icon, String title, String subtitle) =
        result.isEligible
            ? (AppColors.green, Icons.verified_rounded, 'Ready to donate',
                'You meet all requirements. Thank you, hero!')
            : inCooldown
                ? (
                    AppColors.amber,
                    Icons.hourglass_bottom_rounded,
                    'Eligible ${_relativeDays(next)}',
                    'Recovering from your last donation.'
                  )
                : (AppColors.info, Icons.info_rounded, 'Complete your profile',
                    result.reason);

    double? cooldownProgress;
    if (inCooldown && user.lastDonationDate != null) {
      final elapsed =
          DateTime.now().difference(user.lastDonationDate!).inDays;
      cooldownProgress =
          (elapsed / DonationEligibility.cooldownDays).clamp(0.0, 1.0);
    }

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 24.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14.sp)),
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
          if (cooldownProgress != null) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill.r),
              child: LinearProgressIndicator(
                value: cooldownProgress,
                minHeight: 6.h,
                backgroundColor: accent.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _relativeDays(DateTime next) {
    final days = next.difference(DateTime.now()).inDays + 1;
    if (days <= 1) return 'tomorrow';
    return 'in $days days';
  }

  // ---------------------------------------------------------------- Appearance

  Widget _appearanceCard(ThemeData theme) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.themeMode == ThemeMode.dark;
        return AppCard(
          padding: EdgeInsets.all(14.r),
          child: Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadii.md.r),
            ),
            child: Row(
              children: [
                _themeOption(theme, 'Light', Icons.light_mode_rounded,
                    selected: !isDark, onTap: () {
                  if (isDark) themeProvider.toggleTheme();
                }),
                _themeOption(theme, 'Dark', Icons.dark_mode_rounded,
                    selected: isDark, onTap: () {
                  if (!isDark) themeProvider.toggleTheme();
                }),
              ],
            ),
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
            border:
                selected ? Border.all(color: theme.colorScheme.outline) : null,
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

  // ---------------------------------------------------------------- Sign out

  Widget _buildSignOut(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, theme),
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
        label: const Text('Sign Out',
            style: TextStyle(
                color: AppColors.danger, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
          padding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- Helpers

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

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.pill.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Future<void> _openEdit(UserModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (mounted) {
      await context.read<UserProvider>().loadCurrentUser();
    }
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
              child:
                  Icon(Icons.bloodtype_rounded, size: 40.r, color: Colors.white),
            ),
            SizedBox(height: 16.h),
            Text('Life Link',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900)),
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

  void _confirmSignOut(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Sign Out?',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'You will need to log in again to access your account.',
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
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Capture refs before the await so we don't touch a stale context.
              final auth = context.read<AuthProviders>();
              final userProvider = context.read<UserProvider>();
              final navigator = Navigator.of(context);
              await auth.logout();
              // Clear the cached profile so the next account can't briefly see
              // the previous user's data before its own loads.
              userProvider.clearUser();
              // Reset the whole stack to LoginScreen. popUntil(isFirst) is wrong
              // here: after onboarding, MainScreen is the first route, so it
              // would strand a signed-out user on MainScreen.
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// "My Requests" opens the current user's full profile (which has a Requests
/// tab). A tiny redirect widget keeps the row list declarative.
class _MyRequestsRedirect extends StatelessWidget {
  const _MyRequestsRedirect();

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ProfileDetailsScreen(userId: user.uid);
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

/// A single tappable settings row — colored icon chip, title, optional subtitle
/// and a trailing chevron.
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
