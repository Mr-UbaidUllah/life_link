import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VolunteerDetailsScreen extends StatelessWidget {
  final VolunteerModel volunteer;

  const VolunteerDetailsScreen({super.key, required this.volunteer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 350.h,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Hero(
                tag: 'volunteer_${volunteer.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      volunteer.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.person, size: 100.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20.h,
                      left: 24.w,
                      right: 24.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              volunteer.workDescription.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            volunteer.name,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Action: Call only.
                    // A volunteer is a directory entry (its `id` is the
                    // Volunteer-collection doc id, NOT an app-user uid), so an
                    // in-app chat keyed to it would target a phantom recipient
                    // that can never receive or reply. Phone is the real,
                    // reachable contact channel for a volunteer.
                    _buildActionBtn(
                      context,
                      icon: Icons.phone_rounded,
                      label: 'Call Volunteer',
                      onTap: () {
                        if (volunteer.phone != null && volunteer.phone!.isNotEmpty) {
                          _makeCall(volunteer.phone!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Phone number not provided')),
                          );
                        }
                      },
                    ),

                    SizedBox(height: 32.h),

                    if (volunteer.location != null && volunteer.location!.isNotEmpty) ...[
                       _buildInfoTile(Icons.location_on_rounded, 'Location', volunteer.location!, theme),
                       SizedBox(height: 20.h),
                    ],

                    _buildSectionHeader('Professional Bio', theme),
                    SizedBox(height: 12.h),
                    Text(
                      volunteer.bio ?? 'This volunteer has not provided a bio yet.',
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    if (volunteer.skills != null && volunteer.skills!.isNotEmpty) ...[
                      _buildSectionHeader('Skills & Expertise', theme),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: volunteer.skills!.split(',').map((skill) => Chip(
                          label: Text(
                            skill.trim(),
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        )).toList(),
                      ),
                    ],

                    SizedBox(height: 40.h),
                    
                    // Disclaimer / Note
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: AppColors.success, size: 20.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Verified Volunteer Community Member',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 18.sp),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    await launchDialer(phone);
  }
}
