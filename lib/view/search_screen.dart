import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/view/profile/profile_details_scrren.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'bottmNavigation.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int selectedIndex = -1;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  // Cache the streams once — the search field calls setState on every keystroke,
  // which would otherwise resubscribe both Firestore streams (and flash the
  // skeletons) on each character typed.
  late final Stream<List<BloodRequestModel>> _requestStream;
  late final Stream<List<UserModel>> _donorStream;

  @override
  void initState() {
    super.initState();
    _requestStream = context.read<BloodrequestProvider>().requests;
    _donorStream = context.read<UserProvider>().donors;
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Find Donors',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 19.sp,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// SEARCH FIELD
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              color: theme.appBarTheme.backgroundColor,
              child: CustomTextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                prefixIcon: Icons.search_rounded,
                hintText: 'Search by city, name or blood...',
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 20.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                          FocusScope.of(context).unfocus();
                        },
                      ),
              ),
            ),
          ),

          /// BLOOD GROUP SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
              child: Text(
                'Filter by Blood Group',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final isSelected = selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedIndex == index) {
                        selectedIndex = -1;
                      } else {
                        selectedIndex = index;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.2)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                          size: 40.sp,
                        ),
                        Text(
                          bloodGroups[index],
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: bloodGroups.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12.w,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1,
              ),
            ),
          ),

          /// RECENT REQUEST SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Blood Requests',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () => MainScreen.switchTab(MainScreen.tabRequests),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.chevron_right_rounded, size: 16.sp, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Consumer2<BloodrequestProvider, UserProvider>(
              builder: (context, _, userProvider, __) {
                final dismissedIds = userProvider.user?.dismissedRequests ?? [];

                return StreamBuilder<List<BloodRequestModel>>(
                  stream: _requestStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return AppShimmer(
                        child: Column(
                          children: List.generate(3, (_) => const BloodRequestSkeleton()),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _emptyMessage(theme, "No requests found");
                    }

                    final allRequests = snapshot.data!;
                    final query = _searchQuery.toLowerCase();
                    final selectedBlood = selectedIndex != -1 ? bloodGroups[selectedIndex] : null;

                    final filteredRequests = allRequests.where((req) {
                      final matchesQuery = query.isEmpty ||
                          req.city.toLowerCase().contains(query) ||
                          req.hospital.toLowerCase().contains(query) ||
                          req.bloodGroup.toLowerCase().contains(query);

                      final matchesBlood = selectedBlood == null || req.bloodGroup == selectedBlood;

                      final isMine = req.userId == currentUserId;
                      final isDismissed = dismissedIds.contains(req.id);

                      // PROFESSIONAL FIX: Always show user's own requests, even if they'd normally be "dismissed" or hidden by default filtering
                      // but hide other people's dismissed requests.
                      return matchesQuery && matchesBlood && (isMine || !isDismissed);
                    }).toList();

                    if (filteredRequests.isEmpty) {
                      return _emptyMessage(theme, "No requests match your search");
                    }

                    // Adjust display logic to prioritize mine or show a limited set when not searching
                    final displayRequests = (_searchQuery.isEmpty && selectedIndex == -1)
                        ? filteredRequests.take(5).toList()
                        : filteredRequests;

                    return Column(
                      children: displayRequests.map((req) {
                        return HomeContainer(
                          request: req,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailsScreen(request: req),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),

          /// DONORS SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 30.h, 20.w, 15.h),
              child: Consumer<UserProvider>(
                builder: (context, provider, _) {
                  final city = provider.user?.city;
                  return Text(
                    city != null ? 'Donors in $city' : 'Nearby Blood Donors',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                },
              ),
            ),
          ),

          Consumer<UserProvider>(
            builder: (context, provider, child) {
              return StreamBuilder<List<UserModel>>(
                stream: _donorStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: AppShimmer(
                          child: Column(
                            children: List.generate(
                              4,
                              (_) => Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: const UserTileSkeleton(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _emptyMessage(theme, 'No donors available right now'),
                    );
                  }

                  final allDonors = snapshot.data!;
                  final currentUser = provider.user;
                  final query = _searchQuery.toLowerCase();
                  final selectedBlood = selectedIndex != -1 ? bloodGroups[selectedIndex] : null;

                  final filteredDonors = allDonors.where((user) {
                    if (user.uid == currentUserId) return false;
                    final isNearby = (user.city != null && user.city == currentUser?.city) &&
                                     (user.country != null && user.country == currentUser?.country);

                    if (_searchQuery.isEmpty && selectedBlood == null) {
                      if (!isNearby) return false;
                    } else {
                      // Allow showing search results even if not nearby, but keep default view to nearby
                      if (!isNearby && _searchQuery.isEmpty && selectedBlood == null) return false;
                    }
                    final matchesQuery = query.isEmpty ||
                        (user.name?.toLowerCase().contains(query) ?? false) ||
                        (user.bloodGroup?.toLowerCase().contains(query) ?? false);
                    final matchesBlood = selectedBlood == null || user.bloodGroup == selectedBlood;
                    return matchesQuery && matchesBlood;
                  }).toList();

                  if (filteredDonors.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _emptyMessage(
                        theme,
                        _searchQuery.isEmpty && selectedBlood == null
                            ? 'No donors found in your city'
                            : 'No matching donors found',
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final user = filteredDonors[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailsScreen(userId: user.uid),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                              leading: CircleAvatar(
                                radius: 25.r,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                                child: user.profileImage == null ? Icon(Icons.person_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 24.sp) : null,
                              ),
                              title: Text(
                                user.name ?? 'Anonymous',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: theme.colorScheme.onSurface),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.bloodtype_rounded, size: 14.sp, color: theme.colorScheme.primary),
                                        SizedBox(width: 4.w),
                                        Text(
                                          user.bloodGroup ?? '--',
                                          style: TextStyle(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                        ),
                                        SizedBox(width: 12.w),
                                        Icon(Icons.location_on_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                        SizedBox(width: 4.w),
                                        Flexible(
                                          child: Text(
                                            user.city ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.primary, size: 16.sp),
                              ),
                            ),
                          ),
                        );
                      }, childCount: filteredDonors.length),
                    ),
                  );
                },
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: 90.h)),
        ],
      ),
    );
  }

  Widget _emptyMessage(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
