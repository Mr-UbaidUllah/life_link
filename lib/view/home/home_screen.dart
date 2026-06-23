import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/services/location_service.dart';
import 'package:blood_donation/services/notification_database_service.dart';
import 'package:blood_donation/services/stats_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/bottom_navigation.dart';
import 'package:blood_donation/view/edit_profile_screen.dart';
import 'package:blood_donation/view/home/donation_info_screen.dart';
import 'package:blood_donation/view/notification_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// Home — a personalized donor dashboard ordered by the donor's *state and next
/// action*. The screen answers one question top-to-bottom: "Is there someone I
/// can help right now, and am I ready to?"
///
///   who am I + my standing  (header + status hero)
///   → what have I done       (your impact — the retention hook)
///   → what can I do          (quick actions)
///   → who needs me now        (matching requests, critical-first)
///   → what's open near me      (a short glance — full feed is the Requests tab)
///   → community proof          (trimmed impact strip)
///
/// It is deliberately NOT a second request feed, inbox or settings surface —
/// each of those owns its own tab.
class HomeScreen extends StatefulWidget {
  static final GlobalKey<_HomeScreenState> homeKey =
      GlobalKey<_HomeScreenState>();
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<CommunityStats> _statsFuture;
  late final Stream<List<BloodRequestModel>> _requestsStream;
  late final Stream<int> _unreadNotifsStream;
  double? _myLat;
  double? _myLng;

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
    _requestsStream = context.read<BloodrequestProvider>().requests;
    _unreadNotifsStream = NotificationDatabaseService().getUnreadCount();
    LocationService.getCurrentPosition().then((pos) {
      if (pos != null && mounted) {
        setState(() {
          _myLat = pos.latitude;
          _myLng = pos.longitude;
        });
      }
    });
    Future.microtask(() {
      if (mounted) context.read<UserProvider>().loadCurrentUser();
    });
  }

  Future<void> _refresh() async {
    final stats = StatsService().fetchCommunityStats();
    setState(() => _statsFuture = stats);
    await Future.wait([stats, context.read<UserProvider>().loadCurrentUser()]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double? _distanceTo(BloodRequestModel r) {
    if (_myLat == null || _myLng == null || r.lat == null || r.lng == null) {
      return null;
    }
    return LocationService.distanceKm(_myLat!, _myLng!, r.lat!, r.lng!);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final user = userProvider.user;
                return StreamBuilder<List<BloodRequestModel>>(
                  stream: _requestsStream,
                  builder: (context, snapshot) {
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final dismissed = userProvider.dismissedRequestIds;
                    final blocked = user?.blockedUsers ?? const [];
                    final group = user?.bloodGroup;
                    final hasGroup = group != null && group.isNotEmpty;

                    final visible =
                        (snapshot.data ?? const <BloodRequestModel>[])
                            .where(
                              (r) =>
                                  r.userId == uid ||
                                  (!dismissed.contains(r.id) &&
                                      !blocked.contains(r.userId)),
                            )
                            .toList();

                    // Requests that match the donor's own blood type, urgent
                    // first — the single highest-value thing on this screen.
                    final matching = !hasGroup
                        ? <BloodRequestModel>[]
                        : (visible
                              .where(
                                (r) => r.userId != uid && r.bloodGroup == group,
                              )
                              .toList()
                            ..sort(
                              (a, b) => UrgencyLevel.fromName(a.urgency).index
                                  .compareTo(
                                    UrgencyLevel.fromName(b.urgency).index,
                                  ),
                            ));

                    // "Open near you" is a glance at *other* open requests —
                    // explicitly excluding the matches already surfaced above so
                    // the same card never appears twice on one screen.
                    final shownIds = matching.map((r) => r.id).toSet();
                    final nearby =
                        [
                          ...visible.where(
                            (r) => r.userId != uid && !shownIds.contains(r.id),
                          ),
                        ]..sort((a, b) {
                          final da = _distanceTo(a), db = _distanceTo(b);
                          if (da != null && db != null) {
                            final d = da.compareTo(db);
                            if (d != 0) return d;
                          } else if (da != null) {
                            return -1;
                          } else if (db != null) {
                            return 1;
                          }
                          return UrgencyLevel.fromName(
                            a.urgency,
                          ).index.compareTo(
                            UrgencyLevel.fromName(b.urgency).index,
                          );
                        });

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(theme, user),
                        ...Stagger.children([
                          // 1 — Identity "passport": who I am + can I give now.
                          _passport(theme, user, matching.length),
                          // 2 — Bento grid: my impact + the actions I reach for.
                          _bento(theme, user),
                          // 3 — Matching requests carousel — or a nudge to set a
                          // blood type so matching can ever work.
                          if (!hasGroup && user != null)
                            _bloodTypePrompt(theme, user)
                          else if (matching.isNotEmpty)
                            _needsYouNow(theme, matching, group),
                          // 4 — Short list of other open requests nearby.
                          SectionHeaderRow(
                            title: 'Open near you',
                            onSeeAll: () =>
                                MainScreen.switchTab(MainScreen.tabRequests),
                          ),
                          if (loading)
                            const AppShimmer(
                              child: Column(
                                children: [
                                  BloodRequestSkeleton(),
                                  BloodRequestSkeleton(),
                                ],
                              ),
                            )
                          else
                            _nearbyList(theme, nearby, group),
                          // 5 — Community proof.
                          _communitySection(theme),
                        ]),
                        SizedBox(height: 88.h),
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

  // ------------------------------------------------------------------ Header

  Widget _header(ThemeData theme, UserModel? user) {
    final name = (user?.name ?? 'there').trim().split(' ').first;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 12.w, 6.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: user == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileDetailsScreen(userId: user.uid),
                    ),
                  ),
            child: Container(
              padding: EdgeInsets.all(2.5.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 23.r,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.08,
                ),
                backgroundImage: (user?.profileImage ?? '').isNotEmpty
                    ? NetworkImage(user!.profileImage!)
                    : null,
                child: (user?.profileImage ?? '').isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: 26.r,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          _bell(theme),
        ],
      ),
    );
  }

  Widget _bell(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surface,
      shape: CircleBorder(side: BorderSide(color: theme.colorScheme.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationScreen()),
        ),
        child: Padding(
          padding: EdgeInsets.all(9.r),
          child: StreamBuilder<int>(
            stream: _unreadNotifsStream,
            builder: (context, snap) {
              final count = snap.data ?? 0;
              final bell = Icon(
                Icons.notifications_none_rounded,
                size: 22.sp,
                color: theme.colorScheme.onSurface,
              );
              if (count <= 0) return bell;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  bell,
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      constraints: BoxConstraints(minWidth: 16.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppRadii.pill.r),
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- Passport hero

  /// Identity card — who I am (blood type, name) and whether I can give right
  /// now, plus the live availability control. Impact + actions live in the
  /// bento grid below, so this stays a single, scannable surface.
  Widget _passport(ThemeData theme, UserModel? user, int matchCount) {
    // Non-donor (or not opted in): recruitment hero.
    if (user == null || !user.isDonor) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 6.h),
        child: GradientHeroCard(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserDonateBlood()),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Become a lifesaver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'One donation can save up to three lives.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5.sp,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.md.r),
                      ),
                      child: Text(
                        'Become a donor',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 56.sp,
              ),
            ],
          ),
        ),
      );
    }

    // Donor passport — identity + eligibility + the live availability control.
    final result = user.evaluateEligibility();
    final next = user.nextEligibleDate;
    final cooldown = next != null && next.isAfter(DateTime.now());
    final eligibilityText = result.isEligible
        ? 'Eligible to donate'
        : cooldown
        ? 'Eligible in ${next.difference(DateTime.now()).inDays + 1} days'
        : 'Finish your donor profile';
    final group = (user.bloodGroup ?? '').isEmpty ? '?' : user.bloodGroup!;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 6.h),
      child: GradientHeroCard(
        glow: true,
        padding: EdgeInsets.all(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Identity: the donor's blood type, white-on-gradient.
                Container(
                  height: 52.r,
                  width: 52.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    group,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matchCount > 0
                            ? '$matchCount ${matchCount == 1 ? "person needs" : "people need"} your $group blood'
                            : 'You\'re ready to save lives',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            result.isEligible
                                ? Icons.verified_rounded
                                : Icons.hourglass_bottom_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 14.sp,
                          ),
                          SizedBox(width: 5.w),
                          Flexible(
                            child: Text(
                              eligibilityText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Availability control — compact translucent strip.
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 4.h, 6.w, 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadii.md.r),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isAvailable ? Icons.bolt_rounded : Icons.bolt_outlined,
                    color: Colors.white,
                    size: 19.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      user.isAvailable
                          ? 'Available to donate now'
                          : 'Set yourself available',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5.sp,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: user.isAvailable,
                      onChanged: (v) =>
                          context.read<UserProvider>().setAvailability(v),
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------- Bento

  /// A 2-column bento grid — the donor's own impact (donations, lives) plus the
  /// two actions they reach for most. For non-donors it flips entirely to
  /// actions (browse, message, eligibility, become a donor). A real [GridView]
  /// keeps the four tiles on a clean equal-size grid instead of a loose row.
  Widget _bento(ThemeData theme, UserModel? user) {
    final isDonor = user != null && user.isDonor;

    final findRequests = _BentoData(
      icon: Icons.search_rounded,
      title: 'Find',
      subtitle: 'requests',
      color: AppColors.info,
      onTap: () => MainScreen.switchTab(MainScreen.tabRequests),
    );
    final eligibility = _BentoData(
      icon: Icons.health_and_safety_rounded,
      title: 'Check',
      subtitle: 'eligibility',
      color: AppColors.green,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DonationInfoScreen()),
      ),
    );

    final List<_BentoData> tiles;
    if (isDonor) {
      final count = user.donationCount;
      tiles = [
        _BentoData(
          icon: Icons.bloodtype_rounded,
          title: '$count',
          subtitle: count == 1 ? 'Donation' : 'Donations',
          color: AppColors.primary,
          big: true,
        ),
        _BentoData(
          icon: Icons.favorite_rounded,
          title: '${count * 3}',
          subtitle: 'Lives saved',
          color: AppColors.coral,
          big: true,
        ),
        findRequests,
        eligibility,
      ];
    } else {
      tiles = [
        findRequests,
        _BentoData(
          icon: Icons.forum_rounded,
          title: 'Messages',
          color: AppColors.indigo,
          onTap: () => MainScreen.switchTab(MainScreen.tabInbox),
        ),
        eligibility,
        _BentoData(
          icon: Icons.volunteer_activism_rounded,
          title: 'Become',
          subtitle: 'a donor',
          color: AppColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserDonateBlood()),
          ),
        ),
      ];
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 2.h),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12.h,
        crossAxisSpacing: 12.w,
        childAspectRatio: 2.3,
        children: tiles.map((t) => _bentoTile(theme, t)).toList(),
      ),
    );
  }

  Widget _bentoTile(ThemeData theme, _BentoData t) {
    final tile = Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md.r),
            ),
            child: Icon(t.icon, color: t.color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: t.big ? 19.sp : 14.sp,
                    height: 1.1,
                    fontWeight: t.big ? FontWeight.w900 : FontWeight.w800,
                    letterSpacing: t.big ? -0.5 : -0.2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (t.subtitle != null)
                  Text(
                    t.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (t.onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
    if (t.onTap == null) return tile;
    return TapScale(onTap: t.onTap, child: tile);
  }

  // --------------------------------------------------- Blood-type nudge

  Widget _bloodTypePrompt(ThemeData theme, UserModel user) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 2.h),
      child: TapScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
        ),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.water_drop_rounded,
                color: AppColors.amber,
                size: 26.sp,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your blood type',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'So we can match you with requests that need you.',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                size: 22.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- Needs you now

  Widget _needsYouNow(
    ThemeData theme,
    List<BloodRequestModel> matching,
    String? group,
  ) {
    final title = (group != null && group.isNotEmpty)
        ? 'Needs your $group blood'
        : 'Needs you now';
    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
            child: Row(
              children: [
                const Pulse(
                  child: Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 17.sp),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill.r),
                  ),
                  child: Text(
                    '${matching.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 104.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: matching.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, i) => _matchCard(theme, matching[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(ThemeData theme, BloodRequestModel r) {
    final dist = _distanceTo(r);
    final urgency = UrgencyLevel.fromName(r.urgency);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final distLabel = dist == null
        ? null
        : dist < 1
        ? '${(dist * 1000).round()} m'
        : '${dist.toStringAsFixed(1)} km';

    return TapScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PostDetailsScreen(request: r)),
      ),
      child: Container(
        width: 170.w,
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl.r),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Blood-identity block — tinted in the urgency color.
            SizedBox(width: 12.w),
            // Info column.
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UrgencyBadge(level: urgency),
                  SizedBox(height: 8.h),
                  Text(
                    r.title.isEmpty ? '${r.bloodGroup} blood needed' : r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5.sp,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Icon(
                        Icons.local_hospital_rounded,
                        size: 12.sp,
                        color: muted,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          r.hospital.isEmpty ? 'Hospital' : r.hospital,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                      ),
                      if (distLabel != null) ...[
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.near_me_rounded,
                          size: 11.sp,
                          color: AppColors.teal,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          distLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    '${r.bags} ${r.bags == 1 ? "bag" : "bags"}',
                    style: TextStyle(
                      color: urgency.color.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Nearby list

  Widget _nearbyList(
    ThemeData theme,
    List<BloodRequestModel> nearby,
    String? group,
  ) {
    if (nearby.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.xl.r),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 38.sp,
              color: AppColors.green,
            ),
            SizedBox(height: 10.h),
            Text(
              'No open requests right now',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4.h),
            Text(
              'You’re all caught up.',
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    // A short slice only — the full feed lives in the Requests tab.
    return Column(
      children: nearby.take(3).map((r) {
        return RequestCard(
          request: r,
          urgency: UrgencyLevel.fromName(r.urgency),
          distanceKm: _distanceTo(r),
          matchesUser:
              group != null && group.isNotEmpty && r.bloodGroup == group,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(request: r)),
          ),
        );
      }).toList(),
    );
  }

  // ----------------------------------------------------------------- Community

  /// A trimmed, mission-relevant 3-stat strip — not the old six-cell vanity
  /// grid (ambulances / orgs / members didn't help a donor decide anything).
  Widget _communitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
          child: Text(
            'Community impact',
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 17.sp),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl.r),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: FutureBuilder<CommunityStats>(
            future: _statsFuture,
            builder: (context, snap) {
              final s = snap.data;
              return Row(
                children: [
                  _communityStat(
                    theme,
                    'Active donors',
                    s?.donors,
                    AppColors.primary,
                  ),
                  _communityDivider(theme),
                  _communityStat(
                    theme,
                    'Open requests',
                    s?.openRequests,
                    AppColors.amber,
                  ),
                  _communityDivider(theme),
                  _communityStat(
                    theme,
                    'Volunteers',
                    s?.volunteers,
                    AppColors.teal,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _communityStat(
    ThemeData theme,
    String label,
    int? value,
    Color color,
  ) {
    final numberStyle = TextStyle(
      fontSize: 22.sp,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: -0.5,
    );
    return Expanded(
      child: Column(
        children: [
          value == null
              ? Text('—', style: numberStyle)
              : AnimatedCount(
                  value: value,
                  formatter: _fmt,
                  style: numberStyle,
                ),
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityDivider(ThemeData theme) =>
      Container(width: 1, height: 34.h, color: theme.colorScheme.outline);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// Data for one tile in the Home bento grid — either a stat ([big] = true,
/// no tap) or an action (has [onTap], shows a chevron).
class _BentoData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final bool big;
  final VoidCallback? onTap;

  const _BentoData({
    required this.icon,
    required this.title,
    required this.color,
    this.subtitle,
    this.big = false,
    this.onTap,
  });
}

/// Small section header with an optional "See all" action (local to Home).
class SectionHeaderRow extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionHeaderRow({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 17.sp),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18.sp,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
