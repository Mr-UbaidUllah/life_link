import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/user_post_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/edit_profile_screen.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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
        final user = provider.isLoading ? null : provider.postUser;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          bottomNavigationBar:
              user == null || _isMe ? null : _buildActionBar(theme, user),
          body: provider.isLoading
              ? _buildLoading(theme)
              : user == null
                  ? _buildNotFound(theme)
                  : RefreshIndicator(
                      onRefresh: () => context
                          .read<UserProvider>()
                          .loadUserById(widget.userId),
                      color: theme.colorScheme.primary,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        slivers: [
                          SliverToBoxAdapter(child: _buildHeader(theme, user)),
                          SliverToBoxAdapter(child: _buildBody(theme, user)),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  // ====================================================== Header (hero + card)
  // A gradient hero with a floating, elevated stat card that straddles the
  // boundary into the body — the signature focal element of the screen.

  Widget _buildHeader(ThemeData theme, UserModel user) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _buildHero(theme, user),
            // Reserves the lower half of the floating card below the gradient.
            SizedBox(height: 52.h),
          ],
        ),
        Positioned(
          left: 20.w,
          right: 20.w,
          bottom: 0,
          child: FadeSlideIn(
            duration: AppMotion.slow,
            offsetY: 24,
            child: _buildStatCard(theme, user),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(ThemeData theme, UserModel user) {
    final location = _location(user);
    final canPop = Navigator.of(context).canPop();
    final available = user.isDonor && user.isAvailable;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.hero,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl.r)),
      ),
      child: Stack(
        children: [
          Positioned(top: -55.h, right: -45.w, child: _blob(165.r, 0.09)),
          Positioned(bottom: -30.h, left: -50.w, child: _blob(150.r, 0.06)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 56.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (canPop)
                        _circleIcon(Icons.arrow_back_ios_new_rounded,
                            () => Navigator.pop(context))
                      else
                        SizedBox(width: 40.r),
                      const Spacer(),
                      if (_isMe)
                        _circleIcon(Icons.edit_rounded, () => _openEdit(user)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  _heroAvatar(theme, user, available),
                  SizedBox(height: 16.h),
                  Text(
                    user.name ?? 'Anonymous',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _heroSubtitle(user, location, available),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A single elegant meta line: role • location, with an availability dot.
  Widget _heroSubtitle(UserModel user, String location, bool available) {
    final parts = <String>[
      user.isDonor ? 'Blood Donor' : 'Member',
      if (location.isNotEmpty) location,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (available) ...[
          Container(
            width: 7.r,
            height: 7.r,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          SizedBox(width: 6.w),
        ] else ...[
          Icon(
            user.isDonor
                ? Icons.verified_rounded
                : Icons.person_outline_rounded,
            size: 14.sp,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          SizedBox(width: 5.w),
        ],
        Flexible(
          child: Text(
            available ? 'Available now • ${parts.join(' • ')}' : parts.join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      );

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _heroAvatar(ThemeData theme, UserModel user, bool available) {
    final hasImage = user.profileImage != null && user.profileImage!.isNotEmpty;
    final ring = Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8)),
        ],
      ),
      child: CircleAvatar(
        radius: 52.r,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 48.r,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: hasImage ? NetworkImage(user.profileImage!) : null,
          child: hasImage
              ? null
              : Text(
                  (user.name ?? '?').trim().isNotEmpty
                      ? user.name!.trim()[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
        ),
      ),
    );

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Soft pulsing glow when the donor is available to donate now.
        Pulse(enabled: available, maxScale: 1.05, child: ring),
        if (user.isDonor)
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 14.sp),
          ),
      ],
    );
  }

  // ----------------------------------------------------- Floating stat card

  Widget _buildStatCard(ThemeData theme, UserModel user) {
    final group = (user.bloodGroup ?? '').trim();
    final since = '${user.createdAt.year}';

    final List<Widget> cells = user.isDonor
        ? [
            _numCell(theme, user.donationCount, 'Donations'),
            _numCell(theme, user.donationCount * 3, 'Lives Saved'),
            group.isNotEmpty
                ? _bloodCell(theme, group)
                : _textCell(theme, 'Since', since),
          ]
        : [
            group.isNotEmpty
                ? _bloodCell(theme, group)
                : _textCell(theme, '—', 'Blood Group'),
            _textCell(theme, 'Member', 'Status'),
            _textCell(theme, since, 'Since'),
          ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.xl.r),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 6.h,
                  endIndent: 6.h,
                  color: theme.colorScheme.outline,
                ),
              Expanded(child: cells[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numCell(ThemeData theme, int value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedCount(
          value: value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 3.h),
        _statLabel(theme, label),
      ],
    );
  }

  Widget _textCell(ThemeData theme, String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface)),
        SizedBox(height: 3.h),
        _statLabel(theme, label),
      ],
    );
  }

  Widget _bloodCell(ThemeData theme, String group) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        BloodTypeBadge(group: group, size: 34),
        SizedBox(height: 5.h),
        _statLabel(theme, _bloodNote(group) ?? 'Blood Group'),
      ],
    );
  }

  Widget _statLabel(ThemeData theme, String label) => Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      );

  // ============================================================== Body

  Widget _buildBody(ThemeData theme, UserModel user) {
    final about = (user.about ?? '').trim();

    final blocks = <Widget>[
      if (_isMe && user.isDonor)
        _block(AvailabilityToggle(
          value: user.isAvailable,
          onChanged: (v) => context.read<UserProvider>().setAvailability(v),
        )),
      if (about.isNotEmpty || _isMe) _block(_buildAbout(theme, about)),
      if (user.isDonor) _block(_buildImpactSection(theme, user)),
      if (user.isDonor) _block(_buildHealthSection(theme, user)),
      _block(_buildInfoSection(
          theme, 'Contact Information', _contactTiles(theme, user))),
      _block(_buildRequestsSection(theme, user), padded: false),
    ];

    return Padding(
      padding: EdgeInsets.only(top: 22.h, bottom: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: Stagger.children(blocks, step: const Duration(milliseconds: 60)),
      ),
    );
  }

  /// Wraps a section with its horizontal page padding + a uniform bottom gap.
  /// [padded] is false for the requests list, which is full-bleed because
  /// HomeContainer self-insets by 20.w.
  Widget _block(Widget child, {bool padded = true}) => Padding(
        padding: EdgeInsets.only(bottom: 24.h),
        child: padded ? _pad(child) : child,
      );

  Widget _pad(Widget child) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: 20.w), child: child);

  Widget _sectionTitle(ThemeData theme, String text) => Text(
        text,
        style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface),
      );

  // -------------------------------------------------------- Bottom action bar

  Widget _buildActionBar(ThemeData theme, UserModel user) {
    final hasPhone = (user.phone ?? '').trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _actionBtn(
                theme: theme,
                icon: Icons.chat_bubble_rounded,
                label: 'Message',
                primary: !hasPhone,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      name: user.name ?? 'User',
                      imageUrl: user.profileImage,
                      receiverId: user.uid,
                    ),
                  ),
                ),
              ),
            ),
            if (hasPhone) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: _actionBtn(
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

  Widget _actionBtn({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(AppRadii.md.r);
    final fg = primary ? Colors.white : theme.colorScheme.primary;
    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: primary ? AppGradients.hero : null,
          color: primary
              ? null
              : theme.colorScheme.primary.withValues(alpha: 0.10),
          border: primary
              ? null
              : Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.20)),
          boxShadow:
              primary ? AppGradients.glow(AppColors.primary, alpha: 0.3) : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18.sp, color: fg),
              SizedBox(width: 8.w),
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.sp)),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------- About

  Widget _buildAbout(ThemeData theme, String about) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'About'),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(18.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(
            about.isNotEmpty
                ? about
                : 'Tell others about yourself — tap the edit button to add a short bio.',
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withValues(alpha: about.isNotEmpty ? 0.7 : 0.45),
              fontSize: 14.sp,
              height: 1.6,
              fontStyle: about.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- Impact

  /// Donor impact + achievement badges — the retention/gamification layer.
  /// Lives saved uses the standard "1 donation can save up to 3 lives" figure.
  Widget _buildImpactSection(ThemeData theme, UserModel user) {
    final count = user.donationCount;
    final lives = count * 3;
    final badges = <({String label, IconData icon, bool earned})>[
      (label: 'First Drop', icon: Icons.water_drop_rounded, earned: count >= 1),
      (label: 'Regular', icon: Icons.repeat_rounded, earned: count >= 3),
      (label: 'Lifesaver', icon: Icons.favorite_rounded, earned: count >= 5),
      (label: 'Hero', icon: Icons.shield_rounded, earned: count >= 10),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Impact & Achievements'),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: AnimatedStatTile(
                value: count,
                label: 'Donations',
                icon: Icons.volunteer_activism_rounded,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: AnimatedStatTile(
                value: lives,
                label: 'Lives Saved',
                icon: Icons.favorite_rounded,
                color: AppColors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final b in badges)
              BadgeChip(label: b.label, icon: b.icon, earned: b.earned),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------- Health

  Widget _buildHealthSection(ThemeData theme, UserModel user) {
    final eligibility = user.evaluateEligibility();
    final color = eligibility.isEligible
        ? AppColors.green
        : theme.colorScheme.error;
    final lastDonation = user.lastDonationDate == null
        ? 'No record'
        : DateFormat('d MMM yyyy').format(user.lastDonationDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(theme, 'Health & Eligibility'),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md.r),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(
                  eligibility.isEligible
                      ? Icons.check_circle_rounded
                      : Icons.info_rounded,
                  color: color,
                  size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  eligibility.isEligible
                      ? 'Eligible to donate'
                      : eligibility.reason,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _buildInfoSection(theme, '', [
          _buildInfoTile(theme, Icons.monitor_weight_outlined, 'Weight',
              user.weightKg == null ? 'Not provided' : '${user.weightKg} kg'),
          _buildInfoTile(theme, Icons.calendar_today_outlined, 'Last donation',
              lastDonation),
          if (user.healthConditions.isNotEmpty)
            _buildInfoTile(theme, Icons.medical_information_outlined,
                'Conditions', user.healthConditions.join(', ')),
        ]),
      ],
    );
  }

  // ------------------------------------------------------------ Contact

  List<Widget> _contactTiles(ThemeData theme, UserModel user) {
    final hasPhone = (user.phone ?? '').trim().isNotEmpty;
    final location = _location(user);

    return [
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
    ];
  }

  Widget _buildInfoSection(
      ThemeData theme, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          _sectionTitle(theme, title),
          SizedBox(height: 14.h),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg.r),
            border: Border.all(color: theme.colorScheme.outline),
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
          child: Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06)),
        ));
      }
      out.add(tiles[i]);
    }
    return out;
  }

  Widget _buildInfoTile(
      ThemeData theme, IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
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
                child:
                    Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            fontSize: 12.sp)),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                          color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.north_east_rounded,
                    size: 15.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------- Requests

  Widget _buildRequestsSection(ThemeData theme, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pad(_sectionTitle(
            theme, _isMe ? 'Your Blood Requests' : 'Blood Requests')),
        SizedBox(height: 12.h),
        Consumer<UserPostsProvider>(
          builder: (context, provider, _) {
            return StreamBuilder<List<BloodRequestModel>>(
              stream: provider.posts(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return AppShimmer(
                    child: Column(
                      children: const [
                        BloodRequestSkeleton(),
                        BloodRequestSkeleton(),
                      ],
                    ),
                  );
                }

                final requests = snapshot.data ?? const <BloodRequestModel>[];
                if (requests.isEmpty) return _pad(_emptyRequests(theme));

                return Column(
                  children: [
                    for (final req in requests)
                      HomeContainer(
                        request: req,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsScreen(request: req),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _emptyRequests(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 34.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.post_add_rounded,
              size: 44.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15)),
          SizedBox(height: 12.h),
          Text(
            _isMe
                ? "You haven't posted any requests yet"
                : 'No blood requests yet',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 14.sp,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------- Loading / not found

  Widget _buildLoading(ThemeData theme) {
    return Column(
      children: [
        // Hero placeholder block.
        Container(
          height: 250.h,
          decoration: BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(AppRadii.xl.r)),
          ),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
        Transform.translate(
          offset: Offset(0, -52.h),
          child: _pad(AppShimmer(
            child: Container(
              height: 92.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.xl.r),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface, size: 20.sp),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded,
                      size: 56.sp,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.15)),
                  SizedBox(height: 14.h),
                  Text('User not found',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface)),
                  SizedBox(height: 4.h),
                  Text('This profile may have been removed.',
                      style: TextStyle(
                          fontSize: 12.5.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- Helpers

  String _location(UserModel user) => [
        if ((user.city ?? '').trim().isNotEmpty) user.city!.trim(),
        if ((user.country ?? '').trim().isNotEmpty) user.country!.trim(),
      ].join(', ');

  /// Well-known, unambiguous compatibility labels only (avoids wrong claims for
  /// the partial-compatibility groups).
  String? _bloodNote(String group) {
    switch (group.toUpperCase().replaceAll(' ', '')) {
      case 'O-':
        return 'Universal donor';
      case 'AB+':
        return 'Universal recipient';
      default:
        return null;
    }
  }

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
