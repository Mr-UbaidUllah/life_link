import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/services/stats_service.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/home/donation_info_screen.dart';
import 'package:blood_donation/view/profile/profile_details_scrren.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/specific_Bloodgroup_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/contribution.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../user_donate_blood.dart';

class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> homeKey = GlobalKey<_HomeScreenState>();
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  final ScrollController _scrollController = ScrollController();
  late Future<CommunityStats> _statsFuture;

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _statsFuture = StatsService().fetchCommunityStats();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
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
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Request Blood',
                    subtitle: 'Create a request',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
                  ),
                  ActivityCard(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Donate Blood',
                    subtitle: 'Register to give',
                    color: Colors.green.shade600,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDonateBlood())),
                  ),
                  ActivityCard(
                    icon: Icons.local_hospital_rounded,
                    title: 'Ambulance',
                    subtitle: 'Emergency help',
                    color: Colors.blue.shade600,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AmbulanceScreen())),
                  ),
                  ActivityCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Donation Info',
                    subtitle: 'Tips & FAQs',
                    color: Colors.orange.shade700,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationInfoScreen())),
                  ),
                ],
              ),

              // --- Blood Group Selector ---
              const HomeHeader(title: 'Find by Blood Group'),
              SizedBox(
                height: 100.h,
                child: Consumer<UserProvider>(
                  builder: (context, provider, _) {
                    final userGroup = provider.user?.bloodGroup;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: bloodGroups.length,
                      itemBuilder: (context, index) {
                        final group = bloodGroups[index];
                        return _buildBloodGroupItem(context, theme, group, group == userGroup);
                      },
                    );
                  },
                ),
              ),

              // --- Urgent Requests ---
              HomeHeader(
                title: 'Urgent Requests',
                onSeeAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BloodrequestScreen())),
              ),
              _buildUrgentRequests(theme),

              // --- Impact / Contribution (live Firestore counts) ---
              const HomeHeader(title: 'Our Impact'),
              _buildImpactGrid(),
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
                        if (!context.mounted) return;
                        if (success) {
                          await userProvider.loadCurrentUser();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(storage.error ?? 'Could not upload your photo.'),
                              backgroundColor: theme.colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
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
            child: Consumer<UserProvider>(
              builder: (context, provider, _) {
                final user = provider.user;
                final firstName = (user?.name ?? 'there').trim().split(' ').first;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2.h),
                    InkWell(
                      onTap: user != null
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileDetailsScreen(userId: user.uid),
                                ),
                              )
                          : null,
                      child: Text(
                        firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Consumer<UserProvider>(
            builder: (context, provider, _) {
              final group = provider.user?.bloodGroup;
              if (group == null || group.isEmpty) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water_drop_rounded, size: 16.sp, color: theme.colorScheme.primary),
                    SizedBox(width: 5.w),
                    Text(
                      group,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildImpactGrid() {
    return FutureBuilder<CommunityStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final cards = _impactCards(snapshot.data);
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 30.h),
          itemCount: cards.length,
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16.w,
            crossAxisSpacing: 16.w,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  List<Widget> _impactCards(CommunityStats? s) {
    final items = <(String, Color, Color, int?)>[
      ('Active Donors', const Color(0xFFE3F2FD), Colors.blue.shade700, s?.donors),
      ('Open Requests', const Color(0xFFFFF3E0), Colors.orange.shade700, s?.openRequests),
      ('Volunteers', const Color(0xFFE0F7FA), Colors.teal.shade700, s?.volunteers),
      ('Organizations', const Color(0xFFF3E5F5), Colors.purple.shade700, s?.organizations),
      ('Ambulances', const Color(0xFFFFEBEE), Colors.red.shade700, s?.ambulances),
      ('Members', const Color(0xFFE8F5E9), Colors.green.shade700, s?.members),
    ];
    return items.map((it) {
      final count = it.$4;
      return ContributionCard(
        number: count == null ? '—' : _formatCount(count),
        title: it.$1,
        bgColor: it.$2,
        textColor: it.$3,
      );
    }).toList();
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
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

  Widget _buildBloodGroupItem(BuildContext context, ThemeData theme, String group, bool isUserGroup) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SpecificBloodgroupScreen(bloodGroup: group))),
      child: Container(
        width: 75.w,
        margin: EdgeInsets.only(right: 12.w, bottom: 10.h, top: 5.h),
        decoration: BoxDecoration(
          color: isUserGroup ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: isUserGroup ? null : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: isUserGroup
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.water_drop, color: (isUserGroup ? Colors.white : theme.colorScheme.primary).withValues(alpha: 0.15), size: 45.sp),
                Text(
                  group,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, color: isUserGroup ? Colors.white : theme.colorScheme.primary),
                ),
              ],
            ),
            if (isUserGroup) ...[
              SizedBox(height: 4.h),
              Text(
                'You',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 9.sp, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
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
        final userGroup = userProvider.user?.bloodGroup;

        return StreamBuilder<List<BloodRequestModel>>(
          stream: bloodProvider.requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Padding(padding: const EdgeInsets.all(30), child: CircularProgressIndicator(color: theme.colorScheme.primary)));
            }

            final visible = (snapshot.data ?? [])
                .where((req) {
                  final isMine = req.userId == currentUserId;
                  final isDismissed = dismissedIds.contains(req.id);
                  return isMine || !isDismissed;
                })
                .toList();

            // Surface requests matching the user's blood group first.
            if (userGroup != null && userGroup.isNotEmpty) {
              visible.sort((a, b) {
                final aMatch = a.bloodGroup == userGroup ? 0 : 1;
                final bMatch = b.bloodGroup == userGroup ? 0 : 1;
                return aMatch.compareTo(bMatch);
              });
            }

            final requests = visible.take(3).toList();

            if (requests.isEmpty) {
              return _buildEmptyRequests(theme);
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
                    ownerId: req.userId,
                    matchesUser: userGroup != null && userGroup.isNotEmpty && req.bloodGroup == userGroup,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyRequests(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 40.sp, color: Colors.green.shade400),
          SizedBox(height: 12.h),
          Text(
            'No urgent requests right now',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: 4.h),
          Text(
            'You’re all caught up. We’ll surface new needs here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}
