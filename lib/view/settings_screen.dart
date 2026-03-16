import 'package:blood_donation/provider/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import '../widgets/user_tile_widget.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';

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
      Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;
          if (userProvider.isLoading && user == null) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          if (user == null) {
            return Center(
              child: Text(
                'User not found.',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 16.sp),
              ),
            );
          }
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Account', theme),
                UserTile(
                  name: user.name ?? 'User Name',
                  imageUrl: user.profileImage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 30.h),
                
                _buildSectionHeader('Preferences', theme),
                _buildSettingsCard(
                  theme,
                  children: [
                    _buildSettingsTile(
                      theme,
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    _buildDivider(theme),
                    _buildSettingsTile(
                      theme,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & Security',
                      onTap: () {},
                    ),
                    _buildDivider(theme),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        final isDark = themeProvider.themeMode == ThemeMode.dark;
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                          leading: Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              size: 20.sp,
                              color: Colors.blueAccent,
                            ),
                          ),
                          title: Text(
                            isDark ? 'Dark Mode' : 'Light Mode',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          trailing: Switch.adaptive(
                            activeColor: theme.colorScheme.primary,
                            value: isDark,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                SizedBox(height: 30.h),
                
                _buildSectionHeader('More', theme),
                _buildSettingsCard(
                  theme,
                  children: [
                    _buildSettingsTile(
                      theme,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildDivider(theme),
                    _buildSettingsTile(
                      theme,
                      icon: Icons.info_outline_rounded,
                      title: 'About App',
                      onTap: () {},
                    ),
                  ],
                ),
                
                SizedBox(height: 40.h),
                
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final confirm = await _showLogoutDialog(context, theme);
                      if (confirm == true && mounted) {
                        await Provider.of<AuthProviders>(context, listen: false).logout();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.logout_rounded, color: theme.colorScheme.primary),
                    label: Text(
                      'Log Out',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface.withOpacity(0.4);
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20.sp, color: effectiveIconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withOpacity(0.2)),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 56.w, endIndent: 16.w, color: theme.dividerColor.withOpacity(0.05));
  }

  Future<bool?> _showLogoutDialog(BuildContext context, ThemeData theme) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Log Out', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('Are you sure you want to log out from your account?', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Log Out', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
