import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
          );
        }

        final user = provider.postUser;
        if (user == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
            body: Center(child: Text('User not found', style: TextStyle(color: theme.colorScheme.onSurface))),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 280.h,
                    floating: false,
                    pinned: true,
                    elevation: 0,
                    stretch: true,
                    backgroundColor: theme.colorScheme.primary,
                    leading: IconButton(
                      icon: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18.sp),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      stretchModes: const [StretchMode.zoomBackground],
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Enhanced Background Gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Subtle Decorative Circle
                          Positioned(
                            top: -50.h,
                            right: -50.w,
                            child: Container(
                              width: 180.r,
                              height: 180.r,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // User Info Overlay
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 40.h),
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        )
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 58.r,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 54.r,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                                        child: user.profileImage == null
                                            ? Icon(Icons.person_rounded, size: 60.sp, color: theme.colorScheme.primary.withOpacity(0.3))
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (user.isDonor)
                                    Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                          )
                                        ],
                                      ),
                                      child: Icon(Icons.check, color: Colors.white, size: 16.sp),
                                    ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                user.name ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 14.sp, color: Colors.white),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "${user.city ?? 'Unknown City'}, ${user.country ?? 'Unknown'}",
                                      style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 25.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildQuickStat(theme, user.bloodGroup ?? '--', 'Blood Group', Icons.bloodtype),
                                _buildVerticalDivider(theme),
                                _buildQuickStat(theme, user.isDonor ? 'Available' : 'Unavailable', 'Status', Icons.event_available),
                                _buildVerticalDivider(theme),
                                _buildQuickStat(theme, "Verified", 'Identity', Icons.verified_user),
                              ],
                            ),
                          ),
                          TabBar(
                            indicatorColor: theme.colorScheme.primary,
                            indicatorWeight: 3,
                            indicatorSize: TabBarIndicatorSize.label,
                            labelColor: theme.colorScheme.primary,
                            unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                            tabs: const [
                              Tab(text: "Details"),
                              Tab(text: "Requests"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                color: theme.colorScheme.surface,
                child: TabBarView(
                  children: [
                    _buildDetailsTab(theme, user),
                    _buildRequestsTab(theme, user.uid),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildBottomActions(theme, user),
          ),
        );
      },
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 40.h,
      width: 1,
      color: theme.dividerColor.withOpacity(0.1),
    );
  }

  Widget _buildQuickStat(ThemeData theme, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary.withOpacity(0.6), size: 20.sp),
        SizedBox(height: 4.h),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: theme.colorScheme.onSurface)),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12.sp)),
      ],
    );
  }

  Widget _buildDetailsTab(ThemeData theme, user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(theme, 'Contact Information', [
            _buildInfoTile(theme, Icons.phone_android_rounded, 'Mobile', user.phone ?? 'Not provided'),
            _buildInfoTile(theme, Icons.email_outlined, 'Email', user.email),
            _buildInfoTile(theme, Icons.location_city_rounded, 'Address', "${user.city ?? ''}, ${user.country ?? ''}"),
          ]),
          SizedBox(height: 25.h),
          Text(
            "About Donor",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
            ),
            child: Text(
              "Regular blood donor committed to saving lives. I am usually available for urgent blood requests in my city. Feel free to contact me via message or call.",
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 14.sp, height: 1.6),
            ),
          ),
          SizedBox(height: 25.h),
          Text(
            "Social Presence",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: 15.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(theme, Icons.facebook, const Color(0xFF1877F2)),
              SizedBox(width: 15.w),
              _buildSocialIcon(theme, Icons.alternate_email, Colors.redAccent),
              SizedBox(width: 15.w),
              _buildSocialIcon(theme, Icons.message_rounded, Colors.green),
            ],
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        SizedBox(height: 15.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12.sp)),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: theme.colorScheme.onSurface)),
              ],
            ),
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
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Icon(icon, color: color, size: 24.sp),
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
                    Icon(Icons.post_add_rounded, size: 60.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                    SizedBox(height: 16.h),
                    Text("No blood requests yet", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 16.sp)),
                  ],
                ),
              );
            }

            final requests = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(20.r),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailsScreen(request: req),
                        ),
                      );
                    },
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

  Widget _buildBottomActions(ThemeData theme, user) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 15.h, 24.w, 35.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
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
              icon: Icon(Icons.chat_bubble_rounded, size: 18.sp, color: theme.colorScheme.primary),
              label: Text('Message', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              ),
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: user.phone != null ? () => _makePhoneCall(user.phone) : null,
              icon: Icon(Icons.call_rounded, size: 18.sp, color: Colors.white),
              label: Text('Call Donor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                elevation: 5,
                shadowColor: theme.colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
