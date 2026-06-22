import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/services/notification_database_service.dart';
import 'package:blood_donation/services/stats_service.dart';
import 'package:blood_donation/view/notification_screen.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/bottom_navigation.dart';
import 'package:blood_donation/view/home/donation_info_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/specific_blood_group_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/contribution.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/shimmer.dart';
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
  static const List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  final ScrollController _scrollController = ScrollController();
  late Future<CommunityStats> _statsFuture;
  late final Stream<List<BloodRequestModel>> _requestsStream;
  // Cache the unread-notifications stream once; getUnreadCount() opens a new
  // Firestore subscription on each call, so building it inline would resubscribe
  // on every header rebuild.
  final Stream<int> _unreadNotificationsStream =
      NotificationDatabaseService().getUnreadCount();

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
    // Cache the stream once: the provider getter creates a new Firestore
    // subscription on every access, which would resubscribe on each rebuild.
    _requestsStream = context.read<BloodrequestProvider>().requests;
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadCurrentUser();
      }
    });
  }

  Future<void> _refresh() async {
    final stats = StatsService().fetchCommunityStats();
    setState(() => _statsFuture = stats);
    await Future.wait([
      stats,
      context.read<UserProvider>().loadCurrentUser(),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final user = userProvider.user;
                return StreamBuilder<List<BloodRequestModel>>(
                  stream: _requestsStream,
                  builder: (context, snapshot) {
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final dismissedIds = user?.dismissedRequests ?? const [];
                    final userGroup = user?.bloodGroup;

                    final visible = (snapshot.data ?? const <BloodRequestModel>[])
                        .where((req) => req.userId == currentUserId || !dismissedIds.contains(req.id))
                        .toList();

                    final matching = (userGroup == null || userGroup.isEmpty)
                        ? const <BloodRequestModel>[]
                        : visible.where((req) => req.userId != currentUserId && req.bloodGroup == userGroup).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, theme, user),
                        _buildSmartBanner(theme, userGroup, matching),
                        const HomeHeader(title: 'Quick Actions'),
                        _buildQuickActions(),
                        HomeHeader(
                          title: 'Urgent Requests',
                          onSeeAll: () => MainScreen.switchTab(MainScreen.tabRequests),
                        ),
                        if (isLoading)
                          const AppShimmer(
                            child: Column(children: [BloodRequestSkeleton(), BloodRequestSkeleton()]),
                          )
                        else
                          _buildUrgentRequests(theme, visible, userGroup),
                        const HomeHeader(title: 'Find by Blood Group'),
                        _buildBloodGroupChips(theme, userGroup),
                        const HomeHeader(title: 'Our Impact'),
                        _buildImpactCard(theme),
                        SizedBox(height: 90.h),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Header

  Widget _buildHeader(BuildContext context, ThemeData theme, UserModel? user) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 6.h),
      child: Row(
        children: [
          _buildAvatar(theme, user),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                InkWell(
                  onTap: user != null ? () => _openProfile(user) : null,
                  child: Text(
                    (user?.name ?? 'there').trim().split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 21.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationBell(context, theme),
          if (user?.bloodGroup != null && user!.bloodGroup!.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, size: 15.sp, color: theme.colorScheme.primary),
                  SizedBox(width: 4.w),
                  Text(
                    user.bloodGroup!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Bell that opens the notification inbox, with a live unread badge.
  Widget _buildNotificationBell(BuildContext context, ThemeData theme) {
    return StreamBuilder<int>(
      stream: _unreadNotificationsStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Padding(
          padding: EdgeInsets.only(right: 4.w),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, size: 26.sp, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NotificationScreen()),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: 6.w,
                  top: 6.h,
                  child: Container(
                    padding: EdgeInsets.all(count > 9 ? 3.r : 4.r),
                    constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Avatar simply opens the profile screen.
  Widget _buildAvatar(ThemeData theme, UserModel? user) {
    final imageUrl = user?.profileImage;
    return GestureDetector(
      onTap: user != null ? () => _openProfile(user) : null,
      child: Container(
        padding: EdgeInsets.all(2.5.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25), width: 2),
        ),
        child: CircleAvatar(
          radius: 25.r,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Icon(Icons.person_rounded, size: 28.r, color: theme.colorScheme.primary.withValues(alpha: 0.5))
              : null,
        ),
      ),
    );
  }

  void _openProfile(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileDetailsScreen(userId: user.uid)),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  // ---------------------------------------------------------- Smart banner

  /// Live, personalized banner: when open requests match the user's blood
  /// group it becomes an emergency alert; otherwise a donation prompt.
  Widget _buildSmartBanner(ThemeData theme, String? userGroup, List<BloodRequestModel> matching) {
    if (matching.isNotEmpty && userGroup != null && userGroup.isNotEmpty) {
      return _buildEmergencyBanner(theme, userGroup, matching.length);
    }
    return _buildDonateBanner(theme);
  }

  Widget _buildEmergencyBanner(ThemeData theme, String group, int count) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () => MainScreen.switchTab(MainScreen.tabRequests),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 46.r,
                  height: 46.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.bloodtype_rounded, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1 ? '1 person needs $group blood' : '$count people need $group blood',
                        style: TextStyle(color: Colors.white, fontSize: 15.5.sp, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'You can help — see requests that match your type.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.sp, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.8), size: 24.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonateBanner(ThemeData theme) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 12.w, 18.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
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
                  'Be a hero today',
                  style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                ),
                SizedBox(height: 5.h),
                Text(
                  'A single donation can save up to three lives.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.5.sp, height: 1.35),
                ),
                SizedBox(height: 14.h),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserDonateBlood()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
                  ),
                  child: Text('Donate Now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Image.asset('assets/images/blood.png', height: 86.h),
        ],
      ),
    );
  }

  // --------------------------------------------------------- Quick actions

  Widget _buildQuickActions() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Expanded(
            child: ActivityCard(
              icon: Icons.bloodtype_rounded,
              title: 'Request Blood',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
            ),
          ),
          Expanded(
            child: ActivityCard(
              icon: Icons.volunteer_activism_rounded,
              title: 'Donate Blood',
              color: AppColors.green,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserDonateBlood())),
            ),
          ),
          Expanded(
            child: ActivityCard(
              icon: Icons.local_hospital_rounded,
              title: 'Ambulance',
              color: AppColors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AmbulanceScreen())),
            ),
          ),
          Expanded(
            child: ActivityCard(
              icon: Icons.menu_book_rounded,
              title: 'Donation Info',
              color: AppColors.amber,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationInfoScreen())),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------- Urgent requests

  Widget _buildUrgentRequests(ThemeData theme, List<BloodRequestModel> visible, String? userGroup) {
    final sorted = [...visible];
    if (userGroup != null && userGroup.isNotEmpty) {
      // Matching requests first, newest first within each group.
      sorted.sort((a, b) {
        final aMatch = a.bloodGroup == userGroup ? 0 : 1;
        final bMatch = b.bloodGroup == userGroup ? 0 : 1;
        if (aMatch != bMatch) return aMatch.compareTo(bMatch);
        return b.createdAt.compareTo(a.createdAt);
      });
    }
    final requests = sorted.take(3).toList();

    if (requests.isEmpty) {
      return _buildEmptyRequests(theme);
    }

    return Column(
      children: requests.map((req) {
        return HomeContainer(
          request: req,
          matchesUser: userGroup != null && userGroup.isNotEmpty && req.bloodGroup == userGroup,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(request: req)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRequests(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 38.sp, color: AppColors.green),
          SizedBox(height: 10.h),
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

  // ----------------------------------------------------- Blood group chips

  Widget _buildBloodGroupChips(ThemeData theme, String? userGroup) {
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: _bloodGroups.length,
        separatorBuilder: (_, _) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final group = _bloodGroups[index];
          final isYou = group == userGroup;
          return InkWell(
            borderRadius: BorderRadius.circular(22.r),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpecificBloodgroupScreen(bloodGroup: group)),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isYou ? theme.colorScheme.primary : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22.r),
                border: isYou ? null : Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                boxShadow: isYou
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    size: 13.sp,
                    color: isYou ? Colors.white : theme.colorScheme.primary,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    isYou ? '$group · You' : group,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isYou ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------- Impact card

  Widget _buildImpactCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<CommunityStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final s = snapshot.data;
          final stats = <(String, int?, Color)>[
            ('Active Donors', s?.donors, AppColors.blue),
            ('Open Requests', s?.openRequests, AppColors.amber),
            ('Volunteers', s?.volunteers, AppColors.teal),
            ('Organizations', s?.organizations, AppColors.plum),
            ('Ambulances', s?.ambulances, AppColors.primary),
            ('Members', s?.members, AppColors.green),
          ];
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.7,
            children: stats
                .map((it) => ContributionCard(
                      value: it.$2 == null ? '—' : _formatCount(it.$2!),
                      label: it.$1,
                      color: it.$3,
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
