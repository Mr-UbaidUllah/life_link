import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/inbox_screen.dart';
import 'package:blood_donation/view/organization_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/settings_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/view/volunteer_screen.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:blood_donation/widgets/menu_tile.dart';
import 'package:blood_donation/widgets/shimmer.dart';
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
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'More Options',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Improved Profile Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 40.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.surface, theme.colorScheme.primary.withOpacity(0.05)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Consumer2<UserProvider, StorageProvider>(
                      builder: (context, users, storage, _) {
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final imageUrl = users.user?.profileImage;

                        return Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.onSurface.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () async {
                              final file = await pickImage();
                              if (file == null) return;
                              final success = await storage.uploadImage(uid, file);
                              if (success) await users.loadCurrentUser();
                            },
                            onLongPress: imageUrl == null
                                ? null
                                : () async {
                                    final confirm = await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: theme.colorScheme.surface,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                                        title: Text('Remove Profile Image', style: TextStyle(color: theme.colorScheme.onSurface)),
                                        content: Text('Do you want to delete your profile image?', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8))),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text('Delete', style: TextStyle(color: theme.colorScheme.primary)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final success = await storage.deleteImage(uid);
                                      if (success) await users.loadCurrentUser();
                                    }
                                  },
                            child: CircleAvatar(
                              radius: 50.r,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                              child: imageUrl == null ? Icon(Icons.person_rounded, size: 50.r, color: theme.colorScheme.onSurface.withOpacity(0.4)) : null,
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.surface, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 18.sp, color: theme.colorScheme.onPrimary),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Consumer<UserProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) return const UserNameShimmer();
                    final user = provider.user;
                    if (user == null) return Text('User not found', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)));
                    return Column(
                      children: [
                        Text(
                          user.name ?? 'User Name',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop_rounded, size: 16.sp, color: theme.colorScheme.primary),
                              SizedBox(width: 6.w),
                              Text(
                                user.bloodGroup ?? "--",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Container(
                                height: 14.h,
                                width: 1,
                                color: theme.colorScheme.primary.withOpacity(0.2),
                              ),
                              SizedBox(width: 12.w),
                              Icon(Icons.location_on_rounded, size: 16.sp, color: theme.colorScheme.primary),
                              SizedBox(width: 4.w),
                              Text(
                                user.city ?? "Location",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Menu Options
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 20.h),
              children: [
                _buildSectionHeader('Donation Services', theme),
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
                
                SizedBox(height: 15.h),
                
                _buildSectionHeader('Community & Support', theme),
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
                
                SizedBox(height: 15.h),
                
                _buildSectionHeader('Account Settings', theme),
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
                              width: 8.r,
                              height: 8.r,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'App Settings',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                MenuTile(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Support Us',
                  onTap: () {},
                ),
                
                SizedBox(height: 15.h),
                
                MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  iconColor: theme.colorScheme.primary,
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 8.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
