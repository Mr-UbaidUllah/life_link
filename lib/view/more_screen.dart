import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/inbox_screen.dart';
import 'package:blood_donation/view/organization_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/settings_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/view/volunteer_screen.dart';
import 'package:blood_donation/widgets/menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  // Cache once — this screen lives in the nav IndexedStack and rebuilds on
  // every tab change, so an inline getTotalUnreadCount() would resubscribe.
  late final Stream<int> _unreadStream;

  @override
  void initState() {
    super.initState();
    _unreadStream = context.read<MessageProvider>().getTotalUnreadCount();
    Future.microtask(() {
      context.read<UserProvider>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 19.sp,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<UserProvider>().loadCurrentUser(),
          color: theme.colorScheme.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.only(top: 12.h, bottom: 32.h),
            children: [
            _buildProfileHeader(theme),
            SizedBox(height: 24.h),
            _buildSectionLabel('Donation', theme),
            MenuGroup(
              children: [
                MenuTile(
                  icon: Icons.bloodtype_outlined,
                  title: 'Create Blood Request',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
                ),
                MenuTile(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Donate Blood',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDonateBlood())),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            _buildSectionLabel('Account', theme),
            MenuGroup(
              children: [
                StreamBuilder<int>(
                  stream: _unreadStream,
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    return MenuTile(
                      icon: Icons.mark_as_unread_outlined,
                      title: 'Inbox Messages',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen())),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unreadCount > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              constraints: BoxConstraints(minWidth: 20.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14.sp,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            _buildSectionLabel('Community & Support', theme),
            MenuGroup(
              children: [
                MenuTile(
                  icon: Icons.business_outlined,
                  title: 'Partner Organizations',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizationScreen())),
                ),
                MenuTile(
                  icon: Icons.airport_shuttle_outlined,
                  title: 'Ambulance Services',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AmbulanceScreen())),
                ),
                MenuTile(
                  icon: Icons.group_add_outlined,
                  title: 'Work as Volunteer',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VolunteerScreen())),
                ),

              ],
            ),

            SizedBox(height: 24.h),

            MenuGroup(
              children: [
                MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  onTap: () => _confirmSignOut(context, theme),
                ),
              ],
            ),
          ],
        ),
          ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Sign Out?', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'You will need to log in again to access your account.',
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Sign out through the provider so AuthProviders.user is cleared.
              // AuthWrapper's auth stream then renders LoginScreen; pop back to
              // that root rather than stacking a second login screen on top.
              await context.read<AuthProviders>().logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text('Sign Out', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// Tappable profile card at the top of the screen — gives this "Profile"
  /// tab an actual profile (avatar, name, blood group) instead of jumping
  /// straight into menu lists, and opens the full profile on tap.
  Widget _buildProfileHeader(ThemeData theme) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        final name = (user?.name ?? '').trim();
        final bloodGroup = (user?.bloodGroup ?? '').trim();
        final imageUrl = user?.profileImage;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: user == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileDetailsScreen(userId: user.uid),
                        ),
                      ),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Icon(Icons.person_rounded, size: 30.r, color: theme.colorScheme.primary.withValues(alpha: 0.5))
                          : null,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Your Profile' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              if (bloodGroup.isNotEmpty) ...[
                                Icon(Icons.water_drop_rounded, size: 13.sp, color: theme.colorScheme.primary),
                                SizedBox(width: 4.w),
                                Text(
                                  bloodGroup,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                              ],
                              Flexible(
                                child: Text(
                                  'View profile',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 10.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
