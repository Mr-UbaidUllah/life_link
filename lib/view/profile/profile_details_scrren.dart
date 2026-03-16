import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userId;

  const ProfileDetailsScreen({super.key, required this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadUserById(widget.userId);
      }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Donor Profile",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          final user = provider.postUser;
          if (user == null) {
            return Center(child: Text('User not found', style: TextStyle(color: theme.colorScheme.onSurface)));
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                /// PROFILE HEADER
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 50.r,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                              child: user.profileImage == null ? Icon(Icons.person_rounded, size: 50.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)) : null,
                            ),
                          ),
                          if (user.isDonor)
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check, color: Colors.white, size: 14.sp),
                            ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        user.name ?? 'Anonymous',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          SizedBox(width: 4.w),
                          Text(
                            "${user.city ?? 'Unknown City'}, ${user.country ?? 'Unknown'}",
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuickStat(theme, user.bloodGroup ?? '--', 'Blood Group'),
                          Container(height: 30, width: 1, color: theme.dividerColor.withOpacity(0.1), margin: EdgeInsets.symmetric(horizontal: 20.w)),
                          _buildQuickStat(theme, user.isDonor ? 'Available' : 'Unavailable', 'Status'),
                        ],
                      ),
                    ],
                  ),
                ),

                /// TAB BAR
                Container(
                  color: theme.colorScheme.surface,
                  child: TabBar(
                    indicatorColor: theme.colorScheme.primary,
                    indicatorWeight: 3,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    tabs: const [
                      Tab(text: "Details"),
                      Tab(text: "Requests"),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      /// DETAILS TAB
                      _buildDetailsTab(theme, user),

                      /// REQUESTS TAB
                      _buildRequestsTab(theme, user.uid),
                    ],
                  ),
                ),

                /// BOTTOM ACTION BUTTONS
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  name: user.name.toString(),
                                  receiverId: user.uid,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.message_rounded, color: theme.colorScheme.primary),
                          label: Text('Message', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.primary),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: user.phone != null ? () {} : null,
                          icon: const Icon(Icons.call_rounded, color: Colors.white),
                          label: const Text('Call Donor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: theme.colorScheme.primary)),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildDetailsTab(ThemeData theme, user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(theme, 'Contact Information', [
            _buildInfoTile(theme, Icons.phone_rounded, 'Mobile', user.phone ?? 'Not provided'),
            _buildInfoTile(theme, Icons.email_rounded, 'Email', user.email),
            _buildInfoTile(theme, Icons.location_city_rounded, 'City', user.city ?? 'Not provided'),
          ]),
          SizedBox(height: 24.h),
          Text(
            "About Donor",
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: Text(
              "Passionate about saving lives through blood donation. Ready to help whenever needed.",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14.sp, height: 1.5),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialIcon(theme, Icons.facebook, Colors.blue),
              _buildSocialIcon(theme, Icons.alternate_email, theme.colorScheme.primary),
              _buildSocialIcon(theme, Icons.send, Colors.blueAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 11.sp)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: theme.colorScheme.onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(ThemeData theme, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }

  Widget _buildRequestsTab(ThemeData theme, String userId) {
    return Consumer<UserPostsProvider>(
      builder: (context, provider, _) {
        return StreamBuilder<List<BloodRequestModel>>(
          stream: provider.posts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.post_add_rounded, size: 50.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                    SizedBox(height: 12.h),
                    Text("No blood requests yet", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  ],
                ),
              );
            }

            final requests = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: InkWell(
                    onTap: () {},
                    child: HomeContainer(
                      bloodGroup: req.bloodGroup,
                      title: req.title,
                      hospital: req.hospital,
                      date: req.createdAt.toLocal().toString().split(' ')[0],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget tagChip(ThemeData theme, String label) {
    return Chip(
      label: Text(label, style: TextStyle(color: theme.colorScheme.primary)),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      shape: const StadiumBorder(),
    );
  }
}
