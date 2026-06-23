import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/services/report_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/widgets/app_snackbar.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blood_donation/utils/phone_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Full detail view of a single blood request. The donor workflow — accept,
/// cancel, contact-reveal — and trust/safety actions are unchanged; this is a
/// presentation rebuild around a gradient hero + carded sections.
class PostDetailsScreen extends StatefulWidget {
  final BloodRequestModel request;

  const PostDetailsScreen({super.key, required this.request});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  // Live, locally-tracked acceptance state. Initialized from the passed-in
  // request, then updated optimistically as the donor accepts/cancels so the
  // contact-reveal UI reacts without a re-fetch.
  late String _status = widget.request.status;
  late String? _acceptedBy = widget.request.acceptedByUserId;
  bool _busy = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get _acceptedByMe => _acceptedBy != null && _acceptedBy == _uid;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadUserById(widget.request.userId);
      }
    });
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await context
          .read<BloodrequestProvider>()
          .acceptBloodRequest(widget.request.id);
      if (!mounted) return;
      setState(() {
        _status = 'in_progress';
        _acceptedBy = _uid;
        _busy = false;
      });
      AppSnackbar.success(context, 'Thank you! Contact details are unlocked.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // Surface our own clear reason (e.g. "already accepted") from the atomic
      // claim, but never leak a raw Firestore/network error string to the user.
      final msg = e is Exception && e is! FirebaseException
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Could not accept. Please try again.';
      AppSnackbar.error(context, msg);
    }
  }

  Future<void> _cancelAccept() async {
    setState(() => _busy = true);
    try {
      await context
          .read<BloodrequestProvider>()
          .cancelAcceptance(widget.request.id);
      if (!mounted) return;
      setState(() {
        _status = 'open';
        _acceptedBy = null;
        _busy = false;
      });
      AppSnackbar.success(context, 'You stepped back from this request.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppSnackbar.error(context, 'Something went wrong. Please try again.');
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final ok = await launchDialer(phoneNumber);
    if (!ok && mounted) {
      AppSnackbar.error(context, 'Could not launch dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = _uid == widget.request.userId;
    final request = widget.request;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          final postUser = provider.postUser;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHero(theme, request, isOwner, postUser)),
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: Stagger.children([
                        _quickFacts(theme, request),
                        SizedBox(height: 18.h),
                        if (isOwner) ...[
                          _ownerNote(theme),
                          SizedBox(height: 14.h),
                        ],
                        _sectionLabel(theme, 'Contact person'),
                        _contactCard(theme, request, postUser),
                        SizedBox(height: 16.h),
                        _sectionLabel(theme, 'Hospital & location'),
                        _infoCard(theme, request),
                        SizedBox(height: 16.h),
                        _sectionLabel(theme, 'Reason for requirement'),
                        _reasonCard(theme, request),
                        SizedBox(height: 10.h),
                        _postedFooter(theme, request),
                        SizedBox(height: 20.h),
                        // Actions live in the scroll flow, not a pinned bar.
                        _buildActions(theme, request, postUser, isOwner),
                      ], step: const Duration(milliseconds: 55)),
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

  // ====================================================== Gradient hero

  /// Compact identity hero: blood-group disc + title side by side, with a small
  /// live countdown chip (pulses for critical) — the action-driving fact.
  Widget _buildHero(ThemeData theme, BloodRequestModel request, bool isOwner,
      UserModel? postUser) {
    final level = UrgencyLevel.fromName(request.urgency);
    final group = request.bloodGroup.trim();
    final requester = request.contactName.trim().isNotEmpty
        ? request.contactName.trim()
        : (postUser?.name ?? 'Someone');

    return Container(
      decoration: BoxDecoration(
        gradient: level == UrgencyLevel.critical
            ? AppGradients.urgent
            : AppGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.28),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 18.h),
          child: Column(
            children: [
              // Top controls.
              Row(
                children: [
                  _circleIcon(Icons.arrow_back_ios_new_rounded,
                      () => Navigator.pop(context)),
                  const Spacer(),
                  if (isOwner)
                    _circleIcon(Icons.close_rounded,
                        () => _showCancelDialog(context, theme),
                        tooltip: 'Close request')
                  else
                    _heroMenu(theme),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56.r,
                    height: 56.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Text(
                      group.isEmpty ? '?' : group,
                      style: TextStyle(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w900,
                          fontSize: 20.sp,
                          letterSpacing: -0.5),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title.isEmpty
                              ? '$group blood needed'
                              : request.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.3),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Requested by $requester',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Small live countdown chip — pulses when critical.
              Align(
                alignment: Alignment.centerLeft,
                child: Pulse(
                  enabled: level.pulses,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.pill.r),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(level.icon, size: 13.sp, color: Colors.white),
                        SizedBox(width: 6.w),
                        Text(
                          '${level.label} · ${_countdown(request.expiryDate)}',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- At-a-glance quick facts (units / time left / location) ----

  Widget _quickFacts(ThemeData theme, BloodRequestModel request) {
    final city = request.city.trim().isNotEmpty
        ? request.city.trim()
        : (request.country.trim().isNotEmpty ? request.country.trim() : '—');
    return AppCard(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
      child: Row(
        children: [
          _fact(theme, Icons.water_drop_rounded, AppColors.primary,
              '${request.bags}', request.bags == 1 ? 'unit' : 'units'),
          _factDivider(theme),
          _fact(theme, Icons.timer_outlined, AppColors.amber,
              _shortCountdown(request.expiryDate), 'remaining'),
          _factDivider(theme),
          _fact(theme, Icons.location_on_rounded, AppColors.info, city,
              'location'),
        ],
      ),
    );
  }

  Widget _fact(ThemeData theme, IconData icon, Color color, String value,
      String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 7.h),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp)),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _factDivider(ThemeData theme) => Container(
        width: 1,
        height: 38.h,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
      );

  Widget _postedFooter(ThemeData theme, BloodRequestModel request) {
    return Center(
      child: Text(
        'Posted ${DateFormat('d MMM yyyy').format(request.createdAt.toLocal())}',
        style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _heroMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: _circleIconChild(Icons.more_horiz_rounded),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md.r)),
      onSelected: (value) {
        if (value == 'report') _showReportSheet(theme);
        if (value == 'block') _showBlockDialog(theme);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_outlined,
                size: 19.sp, color: theme.colorScheme.onSurface),
            SizedBox(width: 10.w),
            const Text('Report request'),
          ]),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(children: [
            Icon(Icons.block_rounded, size: 19.sp, color: AppColors.danger),
            SizedBox(width: 10.w),
            Text('Block user', style: TextStyle(color: AppColors.danger)),
          ]),
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap, {String? tooltip}) {
    final btn = TapScale(onTap: onTap, child: _circleIconChild(icon));
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  Widget _circleIconChild(IconData icon) => Container(
        padding: EdgeInsets.all(9.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      );

  String _countdown(DateTime by) {
    final d = by.difference(DateTime.now());
    if (d.isNegative) return 'expired';
    if (d.inHours < 1) return '${d.inMinutes}m left';
    if (d.inHours < 24) return '${d.inHours}h left';
    return '${d.inDays}d left';
  }

  /// Compact form for the quick-facts strip ("3h", "5d", "expired").
  String _shortCountdown(DateTime by) {
    final d = by.difference(DateTime.now());
    if (d.isNegative) return 'expired';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  // ====================================================== Body sections

  Widget _ownerNote(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md.r),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text('This is your request.',
                style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(text,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 15.sp)),
      );

  Widget _contactCard(
      ThemeData theme, BloodRequestModel request, UserModel? postUser) {
    final hasImage =
        (postUser?.profileImage ?? '').isNotEmpty;
    final name = request.contactName.trim().isNotEmpty
        ? request.contactName
        : (postUser?.name ?? 'Requester');

    return AppCard(
      padding: EdgeInsets.all(12.r),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileDetailsScreen(userId: request.userId)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            backgroundImage:
                hasImage ? NetworkImage(postUser!.profileImage!) : null,
            child: hasImage
                ? null
                : Icon(Icons.person_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    size: 26.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15.sp)),
                SizedBox(height: 2.h),
                Text('View profile',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 20.sp,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _infoCard(ThemeData theme, BloodRequestModel request) {
    final location = [
      if (request.city.trim().isNotEmpty) request.city.trim(),
      if (request.country.trim().isNotEmpty) request.country.trim(),
    ].join(', ');

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      child: Column(
        children: [
          _infoRow(theme, Icons.local_hospital_rounded, 'Hospital',
              request.hospital.isEmpty ? 'Not specified' : request.hospital),
          _rowDivider(theme),
          _infoRow(theme, Icons.location_on_rounded, 'Location',
              location.isEmpty ? 'Not specified' : location),
        ],
      ),
    );
  }

  Widget _rowDivider(ThemeData theme) => Divider(
        height: 1,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      );

  Widget _infoRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 11.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.md.r),
            ),
            child:
                Icon(icon, color: theme.colorScheme.primary, size: 19.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                        fontSize: 12.sp)),
                SizedBox(height: 2.h),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reasonCard(ThemeData theme, BloodRequestModel request) {
    final reason = request.reason.trim();
    return AppCard(
      padding: EdgeInsets.all(14.r),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          reason.isNotEmpty ? reason : 'No specific reason provided.',
          style: TextStyle(
            color: theme.colorScheme.onSurface
                .withValues(alpha: reason.isNotEmpty ? 0.78 : 0.45),
            fontSize: 14.sp,
            height: 1.45,
            fontStyle: reason.isNotEmpty ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ),
    );
  }

  // ====================================================== Bottom action bar

  Widget _buildActions(ThemeData theme, BloodRequestModel request,
      UserModel? postUser, bool isOwner) {
    // Actions now flow inside the scroll view, so no pinned-bar chrome.
    Widget wrap(Widget child) => child;

    final acceptedBySomeoneElse = _acceptedBy != null && _acceptedBy != _uid;

    // ---- Closed request (e.g. opened via a stale link) ----
    if (_status == 'closed') {
      return wrap(_statusBanner(theme, theme.colorScheme.onSurface,
          Icons.lock_rounded, 'This request is closed',
          'It is no longer accepting donors.'));
    }

    // ---- Owner view ----
    if (isOwner) {
      if (_acceptedBy != null) {
        return wrap(Column(mainAxisSize: MainAxisSize.min, children: [
          _statusBanner(theme, AppColors.success,
              Icons.volunteer_activism_rounded, 'A donor accepted your request',
              'Message them to coordinate the donation.'),
          SizedBox(height: 12.h),
          Row(children: [
            Expanded(
                child: _primaryButton(theme,
                    icon: Icons.chat_bubble_rounded,
                    label: 'Message Donor',
                    onTap: () => _openChat(_acceptedBy!, 'Donor', null))),
            SizedBox(width: 12.w),
            Expanded(child: _closeButton(theme)),
          ]),
        ]));
      }
      return wrap(_closeButton(theme));
    }

    // ---- Donor: already accepted by me → contact unlocked ----
    if (_acceptedByMe) {
      return wrap(Column(mainAxisSize: MainAxisSize.min, children: [
        _statusBanner(theme, AppColors.success, Icons.check_circle_rounded,
            'You’re donating — thank you!',
            'Contact details are unlocked below.'),
        SizedBox(height: 12.h),
        Row(children: [
          Expanded(
            child: _primaryButton(theme,
                icon: Icons.call_rounded,
                label: 'Call Now',
                gradient: AppGradients.success,
                glow: AppColors.green,
                onTap: () => _makeCall(request.phone)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _softButton(theme,
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message',
                onTap: () => _openChat(request.userId,
                    postUser?.name ?? request.contactName,
                    postUser?.profileImage)),
          ),
        ]),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: _busy ? null : _cancelAccept,
          child: Text('Cancel — I can’t donate',
              style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700)),
        ),
      ]));
    }

    // ---- Donor: accepted by someone else ----
    if (acceptedBySomeoneElse) {
      return wrap(Column(mainAxisSize: MainAxisSize.min, children: [
        _statusBanner(theme, AppColors.info, Icons.info_rounded,
            'Another donor is already helping',
            'You can still message the requester.'),
        SizedBox(height: 12.h),
        _softButton(theme,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Message Requester',
            fullWidth: true,
            onTap: () => _openChat(request.userId,
                postUser?.name ?? request.contactName,
                postUser?.profileImage)),
      ]));
    }

    // ---- Donor: open, not yet accepted → contact hidden until accept ----
    return wrap(Column(mainAxisSize: MainAxisSize.min, children: [
      _primaryButton(theme,
          icon: Icons.volunteer_activism_rounded,
          label: 'I’ll Donate · Unlock Contact',
          busy: _busy,
          fullWidth: true,
          onTap: _accept),
      SizedBox(height: 10.h),
      _softButton(theme,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message first',
          fullWidth: true,
          onTap: () => _openChat(request.userId,
              postUser?.name ?? request.contactName, postUser?.profileImage)),
      SizedBox(height: 10.h),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.lock_outline_rounded,
            size: 13.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        SizedBox(width: 5.w),
        Flexible(
          child: Text('Phone is shared only with donors who accept.',
              style: TextStyle(
                  fontSize: 11.5.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
        ),
      ]),
    ]));
  }

  void _openChat(String receiverId, String name, String? imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(name: name, receiverId: receiverId, imageUrl: imageUrl),
      ),
    );
  }

  // ---- Reusable buttons (design-system styled) ----

  Widget _primaryButton(ThemeData theme,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Gradient gradient = AppGradients.hero,
      Color glow = AppColors.primary,
      bool busy = false,
      bool fullWidth = false}) {
    final child = Container(
      width: fullWidth ? double.infinity : null,
      height: 46.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadii.md.r),
        boxShadow: AppGradients.glow(glow, alpha: 0.24),
      ),
      child: busy
          ? SizedBox(
              height: 20.h,
              width: 20.h,
              child: const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 17.sp),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5.sp)),
                ),
              ],
            ),
    );
    return TapScale(onTap: busy ? null : onTap, child: child);
  }

  Widget _softButton(ThemeData theme,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool fullWidth = false}) {
    return TapScale(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.md.r),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 17.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5.sp)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closeButton(ThemeData theme) {
    return _primaryButton(theme,
        icon: Icons.check_circle_outline_rounded,
        label: 'Close Request',
        gradient: AppGradients.info,
        glow: AppColors.blue,
        fullWidth: true,
        onTap: () => _showCancelDialog(context, theme));
  }

  Widget _statusBanner(ThemeData theme, Color color, IconData icon,
      String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22.sp),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13.sp)),
            SizedBox(height: 1.h),
            Text(subtitle,
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11.5.sp)),
          ]),
        ),
      ]),
    );
  }

  // ------------------------------------------------------------ Trust & safety

  void _showReportSheet(ThemeData theme) {
    const reasons = [
      'Spam or fake request',
      'Fraud or scam',
      'Inappropriate content',
      'Duplicate request',
      'Other',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl.r))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report this request',
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 4.h),
              Text('Help keep Life Link safe. Reports are reviewed by our team.',
                  style: TextStyle(
                      fontSize: 12.5.sp,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55))),
              SizedBox(height: 12.h),
              for (final reason in reasons)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.flag_outlined,
                      color: theme.colorScheme.primary, size: 20.sp),
                  title: Text(reason, style: TextStyle(fontSize: 14.sp)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _submitReport(reason);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    try {
      await ReportService().reportRequest(
        requestId: widget.request.id,
        reportedUserId: widget.request.userId,
        reason: reason,
      );
      if (mounted) {
        AppSnackbar.success(context, 'Report submitted. Thank you.');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not submit report.');
    }
  }

  void _showBlockDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Block this user?',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'You won’t see their requests and they won’t be able to reach you. '
          'You can unblock later from settings.',
          style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          TextButton(
            onPressed: () async {
              final userProvider = context.read<UserProvider>();
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext);
              final ok = await userProvider.blockUser(widget.request.userId);
              if (!mounted) return;
              if (ok) {
                AppSnackbar.success(context, 'User blocked.');
                navigator.pop();
              } else {
                AppSnackbar.error(
                    context, 'Could not block user. Please try again.');
              }
            },
            child: Text('Block',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Close Request?',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
            'If you found a donor or want to stop this request, it will be hidden from other users.',
            style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('No',
                  style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () async {
              // Capture provider + navigator from the SCREEN context (still
              // mounted) BEFORE popping — popping deactivates the dialog's own
              // context, and reading providers/Navigator off a deactivated
              // context throws "deactivated widget's ancestor is unsafe".
              final provider = context.read<BloodrequestProvider>();
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext);
              await provider.updateStatus(widget.request.id, 'closed');
              if (mounted) navigator.pop();
            },
            child: Text('Yes, Close it',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
