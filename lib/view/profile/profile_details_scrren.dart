import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/edit_profile_screen.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/refresh_helpers.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool get _isMe => FirebaseAuth.instance.currentUser?.uid == widget.userId;

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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 56.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                  SizedBox(height: 14.h),
                  Text(
                    'User not found',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'This profile may have been removed.',
                    style: TextStyle(fontSize: 12.5.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildHeader(theme, user),
                  SliverToBoxAdapter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 22.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildQuickStat(theme, user.bloodGroup ?? '—', 'Blood Group',
                                  Icons.bloodtype_rounded, AppColors.primary),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildQuickStat(theme, user.isDonor ? 'Donor' : 'Member', 'Status',
                                  Icons.volunteer_activism_rounded, AppColors.green),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildQuickStat(theme, '${user.createdAt.year}', 'Joined',
                                  Icons.event_rounded, AppColors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pinned so the tabs stay reachable while the content scrolls.
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      backgroundColor: theme.colorScheme.surface,
                      tabBar: TabBar(
                        indicatorColor: theme.colorScheme.primary,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
                        tabs: const [
                          Tab(text: "Details"),
                          Tab(text: "Requests"),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                color: theme.scaffoldBackgroundColor,
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

  // ---------------------------------------------------------------- Header

  SliverAppBar _buildHeader(ThemeData theme, UserModel user) {
    final location = [
      if ((user.city ?? '').trim().isNotEmpty) user.city!.trim(),
      if ((user.country ?? '').trim().isNotEmpty) user.country!.trim(),
    ].join(', ');

    return SliverAppBar(
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
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.sp),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isMe)
          IconButton(
            tooltip: 'Edit profile',
            icon: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_rounded, color: Colors.white, size: 18.sp),
            ),
            onPressed: () => _openEdit(user),
          ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          // Collapse progress: 0 = fully expanded, 1 = collapsed to the toolbar.
          final settings = context
              .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          double collapseT = 0;
          if (settings != null) {
            final delta = settings.maxExtent - settings.minExtent;
            if (delta > 0) {
              collapseT = (1 -
                      (settings.currentExtent - settings.minExtent) / delta)
                  .clamp(0.0, 1.0);
            }
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -50.h,
              right: -50.w,
              child: Container(
                width: 180.r,
                height: 180.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -45.h,
              left: -35.w,
              child: Container(
                width: 150.r,
                height: 150.r,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
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
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56.r,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 52.r,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                          child: user.profileImage == null
                              ? Icon(Icons.person_rounded, size: 56.sp, color: theme.colorScheme.primary.withValues(alpha: 0.3))
                              : null,
                        ),
                      ),
                    ),
                    if (user.isDonor)
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 14.sp),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  user.name ?? 'Anonymous',
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (user.isDonor) ...[
                      _HeaderChip(icon: Icons.volunteer_activism_rounded, label: 'Blood Donor'),
                      if (location.isNotEmpty) SizedBox(width: 8.w),
                    ],
                    if (location.isNotEmpty)
                      _HeaderChip(icon: Icons.location_on_rounded, label: location),
                  ],
                ),
              ],
            ),
          ],
        ),
              ),
              // Collapsed-state heading: the user's name fades into the toolbar
              // as the header shrinks, so the pinned bar shows a real heading
              // instead of an empty coloured strip.
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Center(
                        child: Opacity(
                          opacity: collapseT < 0.5
                              ? 0.0
                              : ((collapseT - 0.5) * 2).clamp(0.0, 1.0),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 56.w),
                            child: Text(
                              user.name ?? 'Profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickStat(ThemeData theme, String value, String label, IconData icon, Color accent) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp, color: theme.colorScheme.onSurface),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- Details tab

  Widget _buildDetailsTab(ThemeData theme, UserModel user) {
    final hasPhone = (user.phone ?? '').trim().isNotEmpty;
    final location = [
      if ((user.city ?? '').trim().isNotEmpty) user.city!.trim(),
      if ((user.country ?? '').trim().isNotEmpty) user.country!.trim(),
    ].join(', ');
    final about = (user.about ?? '').trim();

    return RefreshIndicator(
      onRefresh: () => context.read<UserProvider>().loadUserById(widget.userId),
      color: theme.colorScheme.primary,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(theme, 'Contact Information', [
            _buildInfoTile(
              theme,
              Icons.phone_android_rounded,
              'Mobile',
              hasPhone ? user.phone!.trim() : 'Not provided',
              onTap: hasPhone ? () => _makePhoneCall(user.phone) : null,
            ),
            _buildInfoTile(
              theme,
              Icons.mail_rounded,
              'Email',
              user.email,
              onTap: () => _sendEmail(user.email),
            ),
            if (location.isNotEmpty)
              _buildInfoTile(theme, Icons.location_city_rounded, 'Address', location),
          ]),
          if (about.isNotEmpty || _isMe) ...[
            SizedBox(height: 25.h),
            Text(
              'About',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Text(
                about.isNotEmpty
                    ? about
                    : 'Tell others about yourself — tap the edit button above to add a short bio.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: about.isNotEmpty ? 0.7 : 0.45),
                  fontSize: 14.sp,
                  height: 1.6,
                  fontStyle: about.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
          SizedBox(height: 40.h),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
        SizedBox(height: 14.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: _withDividers(theme, children)),
        ),
      ],
    );
  }

  /// Inserts a hairline divider between each tile so rows in a card read as
  /// distinct entries instead of a single merged block.
  List<Widget> _withDividers(ThemeData theme, List<Widget> tiles) {
    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        out.add(Padding(
          padding: EdgeInsets.only(left: 62.w, right: 16.w),
          child: Divider(height: 1, thickness: 1, color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        ));
      }
      out.add(tiles[i]);
    }
    return out;
  }

  Widget _buildInfoTile(ThemeData theme, IconData icon, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.45), fontSize: 12.sp)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.north_east_rounded, size: 15.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Requests tab

  Widget _buildRequestsTab(ThemeData theme, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        // Posts stream live from Firestore — already current; the pull is
        // explicit feedback.
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      color: theme.colorScheme.primary,
      child: Consumer<UserPostsProvider>(
        builder: (context, provider, _) {
        return StreamBuilder<List<BloodRequestModel>>(
          stream: provider.posts(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ShimmerList(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                itemCount: 4,
                itemBuilder: (_, __) => const BloodRequestSkeleton(),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return RefreshableFill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.post_add_rounded, size: 60.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                      SizedBox(height: 16.h),
                      Text(
                        _isMe ? "You haven't posted any requests yet" : 'No blood requests yet',
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 15.sp),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = snapshot.data!;
            return ListView.builder(
              // HomeContainer carries its own horizontal margin.
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
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
              },
            );
          },
        );
      },
        ),
    );
  }

  // -------------------------------------------------------- Bottom actions

  Widget _buildBottomActions(ThemeData theme, UserModel user) {
    final hasPhone = (user.phone ?? '').trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.06))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isMe
            ? _actionButton(
                theme: theme,
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                primary: true,
                onTap: () => _openEdit(user),
              )
            : Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      theme: theme,
                      icon: Icons.chat_bubble_rounded,
                      label: 'Message',
                      primary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              name: user.name ?? 'User',
                              receiverId: user.uid,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasPhone) ...[
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _actionButton(
                        theme: theme,
                        icon: Icons.call_rounded,
                        label: 'Call',
                        primary: true,
                        onTap: () => _makePhoneCall(user.phone),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Bottom-bar action button. [primary] renders a gradient CTA with a soft
  /// red glow; otherwise a tonal secondary button outlined in the brand color.
  Widget _actionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(16.r);
    final fg = primary ? Colors.white : theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: primary
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: primary ? null : theme.colorScheme.primary.withValues(alpha: 0.10),
          border: primary
              ? null
              : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.20)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18.sp, color: fg),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15.sp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- Actions

  Future<void> _openEdit(UserModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (!mounted) return;
    // Reflect any edits both here and on screens watching the current user.
    final provider = context.read<UserProvider>();
    await provider.loadUserById(widget.userId);
    if (!mounted) return;
    await provider.loadCurrentUser();
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber.trim());
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email.trim());
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 12.5.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Pins the profile's TabBar just below the collapsing header so the tabs stay
/// visible (and tappable) no matter how far the content is scrolled.
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate({required this.tabBar, required this.backgroundColor});

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor || oldDelegate.tabBar != tabBar;
  }
}
