import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/edit_profile_screen.dart';
import 'package:blood_donation/view/home/donation_info_screen.dart';
import 'package:blood_donation/view/profile/profile_details_scrren.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/search_screen.dart';
import 'package:blood_donation/view/specific_Bloodgroup_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/contribution.dart';
import 'package:blood_donation/widgets/home_widgets.dart' hide ContributionCard;
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../user_donate_blood.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Premium Header Section ---
              _buildHeader(context, theme),

              // --- Hero / Motivation Card ---
              _buildHeroCard(theme),

              // --- Quick Actions Grid ---
              const HomeHeader(title: 'Quick Actions'),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ActivityCard(
                    imagePath: 'assets/images/blood.png',
                    title: 'Find Donors',
                    subtitle: 'Search nearby',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                  ActivityCard(
                    imagePath: 'assets/images/blod.png',
                    title: 'Requests',
                    subtitle: 'View all needs',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodrequestScreen())),
                  ),
                  ActivityCard(
                    imagePath: 'assets/images/drop.png',
                    title: 'Request Blood',
                    subtitle: "Create post",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
                  ),
                  ActivityCard(
                    imagePath: 'assets/images/drop.png',
                    title: 'Donation Info',
                    subtitle: "Tips & FAQs",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationInfoScreen())),
                  ),
                ],
              ),

              // --- Blood Group Selector ---
              const HomeHeader(title: 'Find by Blood Group'),
              SizedBox(
                height: 100.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: bloodGroups.length,
                  itemBuilder: (context, index) {
                    return _buildBloodGroupItem(context, theme, bloodGroups[index]);
                  },
                ),
              ),

              // --- Urgent Requests ---
              HomeHeader(
                title: 'Urgent Requests',
                onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodrequestScreen())),
              ),
              _buildUrgentRequests(theme),

              // --- Impact / Contribution ---
              const HomeHeader(title: 'Our Impact'),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
                itemCount: contributionData.length,
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16.w,
                  crossAxisSpacing: 16.w,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final item = contributionData[index];
                  return ContributionCard(
                    number: item.number,
                    title: item.title,
                    bgColor: item.bgColor,
                    textColor: item.textColor,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 15.h),
      child: Row(
        children: [
          Consumer2<StorageProvider, UserProvider>(
            builder: (context, storage, userProvider, child) {
              final imageUrl = userProvider.user?.profileImage;
              final uid = FirebaseAuth.instance.currentUser?.uid;

              return GestureDetector(
                onTap: (storage.isLoading || uid == null)
                    ? null
                    : () async {
                        final file = await pickImage();
                        if (file == null) return;
                        final success = await storage.uploadImage(uid, file);
                        if (success) await userProvider.loadCurrentUser();
                      },
                child: Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, Colors.orangeAccent],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28.r,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? Icon(Icons.person, size: 30.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)) : null,
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                ),
                Consumer<UserProvider>(
                  builder: (context, provider, _) {
                    final user = provider.user;
                    return InkWell(
                      onTap: user != null
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileDetailsScreen(userId: user.uid),
                                ),
                              )
                          : null,
                      child: Text(
                        user?.name ?? "User",
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
            },
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined, size: 28.sp, color: theme.colorScheme.onSurface),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  'Be a Hero Today',
                  style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your small contribution can save a life and bring a smile back.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.sp, fontWeight: FontWeight.w400, height: 1.4),
                ),
                SizedBox(height: 15.h),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDonateBlood())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  ),
                  child: Text('Donate Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Image.asset('assets/images/blood.png', height: 100.h),
        ],
      ),
    );
  }

  Widget _buildBloodGroupItem(BuildContext context, ThemeData theme, String group) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpecificBloodgroupScreen(bloodGroup: group))),
      child: Container(
        width: 75.w,
        margin: EdgeInsets.only(right: 12.w, bottom: 10.h, top: 5.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: theme.colorScheme.onSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.water_drop, color: theme.colorScheme.primary.withValues(alpha: 0.1), size: 45.sp),
                Text(
                  group,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentRequests(ThemeData theme) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Consumer2<BloodrequestProvider, UserProvider>(
      builder: (context, bloodProvider, userProvider, _) {
        final dismissedIds = userProvider.user?.dismissedRequests ?? [];

        return StreamBuilder<List<BloodRequestModel>>(
          stream: bloodProvider.requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(color: theme.colorScheme.primary)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Text("No urgent requests at the moment.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14.sp)),
              );
            }

            final requests = snapshot.data!
                .where((req) {
                  final isMine = req.userId == currentUserId;
                  final isDismissed = dismissedIds.contains(req.id);
                  return isMine || !isDismissed;
                })
                .take(3)
                .toList();

            if (requests.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(20.w),
                child: Text("No urgent requests at the moment.", style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14.sp)),
              );
            }

            return Column(
              children: requests.map((req) {
                return InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsScreen(request: req))),
                  child: HomeContainer(
                    bloodGroup: req.bloodGroup,
                    title: req.title,
                    hospital: req.hospital,
                    date: req.createdAt.toLocal().toString().split(' ')[0],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
