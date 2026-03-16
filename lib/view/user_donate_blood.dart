import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/widgets/donate_blood_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class UserDonateBlood extends StatefulWidget {
  const UserDonateBlood({super.key});

  @override
  State<UserDonateBlood> createState() => _UserDonateBloodState();
}

class _UserDonateBloodState extends State<UserDonateBlood> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
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
          'Be a Donor',
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
        builder: (context, provider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              children: [
                /// HERO DONATION CARD
                Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Willing to Donate?',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Enable this to show your profile to those in need of blood.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Switch.adaptive(
                        activeColor: theme.colorScheme.primary,
                        value: provider.isWilling,
                        onChanged: (val) {
                          provider.toggleDonate(val);
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 30.h),

                if (provider.isLoading)
                  Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: CircularProgressIndicator(color: theme.colorScheme.primary),
                  ),

                if (provider.isWilling && provider.user != null)
                  _buildProfileDetails(theme, provider),
                  
                if (!provider.isWilling && !provider.isLoading)
                  _buildInfoBanner(theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileDetails(ThemeData theme, UserProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.w, bottom: 16.h),
          child: Text(
            'PUBLIC PROFILE INFO',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              userTile(theme, 'Full Name', provider.user!.name.toString(), Icons.person_outline_rounded),
              _buildDivider(theme),
              userTile(theme, 'Blood Group', provider.user!.bloodGroup.toString(), Icons.bloodtype_rounded),
              _buildDivider(theme),
              userTile(theme, 'Phone Number', provider.user!.phone.toString(), Icons.phone_android_rounded),
              _buildDivider(theme),
              userTile(theme, 'City', provider.user!.city.toString(), Icons.location_city_rounded),
              _buildDivider(theme),
              userTile(theme, 'Country', provider.user!.country.toString(), Icons.public_rounded),
              _buildDivider(theme),
              userTile(theme, 'Email Address', provider.user!.email.toString(), Icons.email_outlined),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Note: Only this information will be visible to seekers.',
          style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 24.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              'When disabled, your profile will be hidden from donor search results.',
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.primary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(height: 1, indent: 50.w, color: theme.dividerColor.withOpacity(0.05));
  }
}
