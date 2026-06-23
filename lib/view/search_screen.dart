import 'package:blood_donation/core/constants/app_constants.dart';
import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

enum _Mode { donors, requests }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  _Mode _mode = _Mode.donors;
  String? _group; // null == all
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  late final Stream<List<BloodRequestModel>> _requestStream;
  late final Stream<List<UserModel>> _donorStream;

  @override
  void initState() {
    super.initState();
    _requestStream = context.read<BloodrequestProvider>().requests;
    _donorStream = context.read<UserProvider>().donors;
    Future.microtask(() {
      if (mounted) context.read<UserProvider>().loadCurrentUser();
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Discover',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24.sp)),
      ),
      body: Column(
        children: [
          _searchField(theme),
          _modeToggle(theme),
          _groupChips(theme),
          SizedBox(height: 6.h),
          Expanded(
            child: _mode == _Mode.donors
                ? _donorResults(theme)
                : _requestResults(theme),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ Search field

  Widget _searchField(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: _mode == _Mode.donors
              ? 'Search donors by name or city…'
              : 'Search requests by hospital or city…',
          prefixIcon: Icon(Icons.search_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 20.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Mode toggle

  Widget _modeToggle(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.lg.r),
        ),
        child: Row(
          children: [
            _modeTab(theme, _Mode.donors, 'Donors', Icons.people_alt_rounded),
            _modeTab(theme, _Mode.requests, 'Requests', Icons.bloodtype_rounded),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(ThemeData theme, _Mode mode, String label, IconData icon) {
    final selected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.hero : null,
            borderRadius: BorderRadius.circular(AppRadii.md.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17.sp,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5.sp,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Group chips

  Widget _groupChips(ThemeData theme) {
    final options = <String?>[null, ...kBloodGroups];
    return SizedBox(
      height: 50.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        itemCount: options.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final value = options[i];
          final selected = _group == value;
          return GestureDetector(
            onTap: () => setState(() => _group = value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.md.r),
                border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline),
              ),
              child: Text(value ?? 'All',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------- Donor results

  Widget _donorResults(ThemeData theme) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final me = provider.user;
        return StreamBuilder<List<UserModel>>(
          stream: _donorStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppShimmer(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: List.generate(
                      6,
                      (_) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: const UserTileSkeleton())),
                ),
              );
            }
            final q = _query.toLowerCase();
            var donors = (snapshot.data ?? const <UserModel>[]).where((u) {
              if (u.uid == uid) return false;
              if (_group != null && u.bloodGroup != _group) return false;
              if (q.isEmpty) return true;
              return (u.name?.toLowerCase().contains(q) ?? false) ||
                  (u.city?.toLowerCase().contains(q) ?? false) ||
                  (u.bloodGroup?.toLowerCase().contains(q) ?? false);
            }).toList();

            // Available donors first, then same-city, then name.
            donors.sort((a, b) {
              if (a.isAvailable != b.isAvailable) {
                return a.isAvailable ? -1 : 1;
              }
              final aCity = (me?.city != null && a.city == me?.city) ? 0 : 1;
              final bCity = (me?.city != null && b.city == me?.city) ? 0 : 1;
              if (aCity != bCity) return aCity.compareTo(bCity);
              return (a.name ?? '').compareTo(b.name ?? '');
            });

            if (donors.isEmpty) {
              return _empty(theme, Icons.people_outline_rounded,
                  'No donors found', 'Try a different blood group or city.');
            }

            final availableCount = donors.where((d) => d.isAvailable).length;
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
              itemCount: donors.length + (availableCount > 0 ? 1 : 0),
              itemBuilder: (context, index) {
                if (availableCount > 0 && index == 0) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      '$availableCount available to donate now',
                      style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp),
                    ),
                  );
                }
                final d = donors[availableCount > 0 ? index - 1 : index];
                return _donorCard(theme, d);
              },
            );
          },
        );
      },
    );
  }

  Widget _donorCard(ThemeData theme, UserModel d) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TapScale(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ProfileDetailsScreen(userId: d.uid))),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl.r),
            border: Border.all(
                color: d.isAvailable
                    ? AppColors.green.withValues(alpha: 0.4)
                    : theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 27.r,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: (d.profileImage ?? '').isNotEmpty
                        ? NetworkImage(d.profileImage!)
                        : null,
                    child: (d.profileImage ?? '').isEmpty
                        ? Icon(Icons.person_rounded,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
                        : null,
                  ),
                  if (d.isAvailable)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14.r,
                        height: 14.r,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(d.name ?? 'Anonymous',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15.sp)),
                        ),
                        if (d.isAvailable) ...[
                          SizedBox(width: 8.w),
                          const StatusPill(
                              label: 'Available',
                              color: AppColors.green,
                              icon: Icons.bolt_rounded),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13.sp,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45)),
                        SizedBox(width: 3.w),
                        Flexible(
                          child: Text(d.city ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5.sp,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              BloodTypeBadge(group: d.bloodGroup ?? '', size: 42),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------- Request results

  Widget _requestResults(ThemeData theme) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final dismissed = provider.dismissedRequestIds;
        final blocked = provider.user?.blockedUsers ?? const [];
        return StreamBuilder<List<BloodRequestModel>>(
          stream: _requestStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppShimmer(
                child: Column(
                    children:
                        List.generate(4, (_) => const BloodRequestSkeleton())),
              );
            }
            final q = _query.toLowerCase();
            final list = (snapshot.data ?? const <BloodRequestModel>[])
                .where((r) {
              final mine = r.userId == uid;
              if (!mine &&
                  (dismissed.contains(r.id) || blocked.contains(r.userId))) {
                return false;
              }
              if (_group != null && r.bloodGroup != _group) return false;
              if (q.isEmpty) return true;
              return r.city.toLowerCase().contains(q) ||
                  r.hospital.toLowerCase().contains(q) ||
                  r.title.toLowerCase().contains(q) ||
                  r.bloodGroup.toLowerCase().contains(q);
            }).toList()
              ..sort((a, b) => UrgencyLevel.fromName(a.urgency)
                  .index
                  .compareTo(UrgencyLevel.fromName(b.urgency).index));

            if (list.isEmpty) {
              return _empty(theme, Icons.bloodtype_outlined,
                  'No requests found', 'Try a different filter or search.');
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: 4.h, bottom: 100.h),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final r = list[index];
                return RequestCard(
                  request: r,
                  urgency: UrgencyLevel.fromName(r.urgency),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => PostDetailsScreen(request: r))),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _empty(ThemeData theme, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 64.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
            SizedBox(height: 14.h),
            Text(title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 6.h),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
          ],
        ),
      ),
    );
  }
}
