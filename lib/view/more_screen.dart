import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/inbox_screen.dart';
import 'package:blood_donation/view/organization_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/settings_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/view/volunteer_screen.dart';
import 'package:blood_donation/widgets/menu_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'auth/login_screen.dart';

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
          'Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 19.sp,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 12.h, bottom: 32.h),
          children: [
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
                  stream: context.read<MessageProvider>().getTotalUnreadCount(),
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
                MenuTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Support Us',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Support options are coming soon. Thank you! ❤️'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                      ),
                    );
                  },
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
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            child: Text('Sign Out', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
