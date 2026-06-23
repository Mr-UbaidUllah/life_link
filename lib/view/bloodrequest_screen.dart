import 'package:blood_donation/core/constants/app_constants.dart';
import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/services/location_service.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/app_snackbar.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:blood_donation/widgets/ui_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// High-level lenses over the feed. The blood-group filter and free-text
/// search are progressive (behind app-bar affordances) so the feed itself
/// stays the focus — only this one lens row is ever pinned.
enum _Lens { all, critical, nearMe, myType }

extension _LensMeta on _Lens {
  String get label => switch (this) {
        _Lens.all => 'All',
        _Lens.critical => 'Critical',
        _Lens.nearMe => 'Near me',
        _Lens.myType => 'My type',
      };

  IconData get icon => switch (this) {
        _Lens.all => Icons.dashboard_rounded,
        _Lens.critical => Icons.priority_high_rounded,
        _Lens.nearMe => Icons.near_me_rounded,
        _Lens.myType => Icons.favorite_rounded,
      };
}

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  _Lens _lens = _Lens.all;
  String? _selectedGroup; // null == all groups
  String _query = '';
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  double? _myLat;
  double? _myLng;

  late final Stream<List<BloodRequestModel>> _requestStream;

  @override
  void initState() {
    super.initState();
    _requestStream = context.read<BloodrequestProvider>().requests;
    Future.microtask(() {
      if (mounted) context.read<UserProvider>().loadCurrentUser();
    });
    LocationService.getCurrentPosition().then((pos) {
      if (pos != null && mounted) {
        setState(() {
          _myLat = pos.latitude;
          _myLng = pos.longitude;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double? _distanceTo(BloodRequestModel r) {
    if (_myLat == null || _myLng == null || r.lat == null || r.lng == null) {
      return null;
    }
    return LocationService.distanceKm(_myLat!, _myLng!, r.lat!, r.lng!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Consumer2<BloodrequestProvider, UserProvider>(
          builder: (context, _, userProvider, __) {
            final dismissedIds = userProvider.dismissedRequestIds;
            final blockedIds = userProvider.user?.blockedUsers ?? const [];
            final userGroup = userProvider.user?.bloodGroup;
            final hasType = userGroup != null && userGroup.isNotEmpty;

            return StreamBuilder<List<BloodRequestModel>>(
              stream: _requestStream,
              builder: (context, snapshot) {
                final loading =
                    snapshot.connectionState == ConnectionState.waiting;

                // Visible universe: my own posts always; others unless
                // dismissed or blocked.
                final all = (snapshot.data ?? const <BloodRequestModel>[])
                    .where((req) {
                  final mine = req.userId == currentUserId;
                  final dismissed = dismissedIds.contains(req.id);
                  final blocked = blockedIds.contains(req.userId);
                  return mine || (!dismissed && !blocked);
                }).toList();

                // Base = group + search applied; lens counts derive from this.
                final base = _base(all);
                final criticalCount =
                    base.where((r) => _matchesLens(r, _Lens.critical, userGroup)).length;

                final list = base
                    .where((r) => _matchesLens(r, _lens, userGroup))
                    .toList()
                  ..sort((a, b) => _sort(a, b, userGroup));

                final showBanner = !loading &&
                    !_searchActive &&
                    _lens != _Lens.critical &&
                    criticalCount > 0;
                final filtersActive = _selectedGroup != null || _query.isNotEmpty;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    _appBar(theme, canPop, all, currentUserId),
                    if (_searchActive)
                      SliverToBoxAdapter(child: _searchField(theme)),
                    if (showBanner)
                      SliverToBoxAdapter(
                        child: _criticalBanner(theme, criticalCount),
                      ),
                    if (filtersActive)
                      SliverToBoxAdapter(child: _activeFilters(theme)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _LensHeaderDelegate(
                        height: 60.h,
                        child: _lensBar(theme, base, userGroup, hasType),
                      ),
                    ),
                    if (loading)
                      SliverToBoxAdapter(
                        child: AppShimmer(
                          child: Column(
                            children: const [
                              BloodRequestSkeleton(),
                              BloodRequestSkeleton(),
                              BloodRequestSkeleton(),
                            ],
                          ),
                        ),
                      )
                    else if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _emptyState(theme),
                      )
                    else
                      SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final req = list[index];
                          final mine = req.userId == currentUserId;
                          return Padding(
                            padding: EdgeInsets.only(top: index == 0 ? 4.h : 0),
                            child: Dismissible(
                              key: Key(req.id),
                              direction: mine
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              background: _dismissBg(theme),
                              onDismissed: mine
                                  ? null
                                  // Keep the dismissal until just past the
                                  // request's own expiry — after that it's gone
                                  // from the feed anyway and TTL reaps the doc.
                                  : (_) => userProvider.dismissRequest(
                                        req.id,
                                        req.expiryDate
                                            .add(const Duration(days: 1)),
                                      ),
                              child: RequestCard(
                                request: req,
                                urgency: UrgencyLevel.fromName(req.urgency),
                                distanceKm: _distanceTo(req),
                                matchesUser: hasType &&
                                    req.bloodGroup == userGroup,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PostDetailsScreen(request: req)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: 110.h)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Filtering

  /// Group + search filter only (lens-independent). Lens counts derive here.
  List<BloodRequestModel> _base(List<BloodRequestModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((r) {
      if (_selectedGroup != null && r.bloodGroup != _selectedGroup) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay =
            '${r.title} ${r.hospital} ${r.city} ${r.bloodGroup}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  bool _matchesLens(BloodRequestModel r, _Lens lens, String? userGroup) {
    switch (lens) {
      case _Lens.all:
        return true;
      case _Lens.critical:
        return UrgencyLevel.fromName(r.urgency) == UrgencyLevel.critical;
      case _Lens.nearMe:
        return _distanceTo(r) != null;
      case _Lens.myType:
        return userGroup != null &&
            userGroup.isNotEmpty &&
            r.bloodGroup == userGroup;
    }
  }

  int _sort(BloodRequestModel a, BloodRequestModel b, String? userGroup) {
    if (_lens == _Lens.nearMe) {
      final da = _distanceTo(a), db = _distanceTo(b);
      if (da != null && db != null) return da.compareTo(db);
    }
    if (userGroup != null && userGroup.isNotEmpty) {
      final am = a.bloodGroup == userGroup ? 0 : 1;
      final bm = b.bloodGroup == userGroup ? 0 : 1;
      if (am != bm) return am.compareTo(bm);
    }
    final u = UrgencyLevel.fromName(a.urgency)
        .index
        .compareTo(UrgencyLevel.fromName(b.urgency).index);
    if (u != 0) return u;
    return b.createdAt.compareTo(a.createdAt);
  }

  // ------------------------------------------------------------------ AppBar

  Widget _appBar(ThemeData theme, bool canPop, List<BloodRequestModel> all,
      String? currentUserId) {
    final groupActive = _selectedGroup != null;
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: canPop ? 0 : 20.w,
      leading: canPop
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.onSurface, size: 20.sp),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text('Requests',
          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26.sp)),
      actions: [
        IconButton(
          tooltip: _searchActive ? 'Close search' : 'Search requests',
          onPressed: _toggleSearch,
          icon: Icon(_searchActive ? Icons.search_off_rounded : Icons.search_rounded,
              color: theme.colorScheme.onSurface, size: 23.sp),
        ),
        // Blood-type filter (progressive — opens a sheet). Dot when active.
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Filter by blood type',
              onPressed: () => _openGroupSheet(theme),
              icon: Icon(Icons.tune_rounded,
                  color: theme.colorScheme.onSurface, size: 22.sp),
            ),
            if (groupActive)
              Positioned(
                top: 10.h,
                right: 10.w,
                child: Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: theme.scaffoldBackgroundColor, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        if (all.any((r) => r.userId != currentUserId))
          IconButton(
            tooltip: 'Clear feed',
            onPressed: () => _showClearDialog(theme, all),
            icon: Icon(Icons.delete_sweep_rounded,
                color: theme.colorScheme.onSurface, size: 22.sp),
          ),
        SizedBox(width: 4.w),
      ],
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchActive = !_searchActive;
      if (!_searchActive) {
        _searchController.clear();
        _query = '';
        FocusScope.of(context).unfocus();
      }
    });
  }

  // ------------------------------------------------------------- Search field

  Widget _searchField(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
      child: Container(
        height: 48.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadii.md.r),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(fontSize: 14.5.sp),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search hospital, city or blood type',
                  hintStyle: TextStyle(
                      fontSize: 13.5.sp,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                child: Icon(Icons.close_rounded,
                    size: 18.sp,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Critical banner

  Widget _criticalBanner(ThemeData theme, int count) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 4.h),
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.lg.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg.r),
          onTap: () => setState(() => _lens = _Lens.critical),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg.r),
              border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.priority_high_rounded,
                      color: Colors.white, size: 18.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count == 1
                            ? '1 critical request needs blood now'
                            : '$count critical requests need blood now',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5.sp,
                            color: theme.colorScheme.primary),
                      ),
                      SizedBox(height: 1.h),
                      Text('Tap to view',
                          style: TextStyle(
                              fontSize: 11.5.sp,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.primary, size: 22.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Active filters

  Widget _activeFilters(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 2.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 6.h,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (_selectedGroup != null)
            _removablePill(theme, 'Type: $_selectedGroup',
                () => setState(() => _selectedGroup = null)),
          if (_query.isNotEmpty)
            _removablePill(theme, 'Search: "$_query"', () {
              _searchController.clear();
              setState(() => _query = '');
            }),
        ],
      ),
    );
  }

  Widget _removablePill(ThemeData theme, String label, VoidCallback onClear) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 8.w, 6.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary)),
            SizedBox(width: 4.w),
            Icon(Icons.close_rounded,
                size: 14.sp, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- Pinned lens bar

  Widget _lensBar(ThemeData theme, List<BloodRequestModel> base,
      String? userGroup, bool hasType) {
    // Hide "My type" until the user has a blood group set.
    final visible = [
      _Lens.all,
      _Lens.critical,
      _Lens.nearMe,
      if (hasType) _Lens.myType,
    ];
    int countFor(_Lens l) =>
        base.where((r) => _matchesLens(r, l, userGroup)).length;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: visible.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final lens = visible[i];
          final selected = _lens == lens;
          final count = countFor(lens);
          return Center(
            child: GestureDetector(
              onTap: () => setState(() => _lens = lens),
              child: AnimatedContainer(
              duration: AppMotion.fast,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              height: 44.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill.r),
                border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(lens.icon,
                      size: 15.sp,
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                  SizedBox(width: 6.w),
                  Text(lens.label,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface)),
                  SizedBox(width: 6.w),
                  Container(
                    constraints: BoxConstraints(minWidth: 18.w),
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.25)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadii.pill.r),
                    ),
                    child: Text('$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------- Blood-group sheet

  void _openGroupSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheet) {
            Widget chip(String? value) {
              final selected = _selectedGroup == value;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedGroup = value);
                  Navigator.pop(sheetContext);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadii.md.r),
                    border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline),
                  ),
                  child: Text(value ?? 'All types',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp,
                          color: selected
                              ? Colors.white
                              : theme.colorScheme.onSurface)),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 28.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter by blood type',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18.sp)),
                  SizedBox(height: 4.h),
                  Text('Show only requests for a specific group.',
                      style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55))),
                  SizedBox(height: 18.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      chip(null),
                      for (final g in kBloodGroups) chip(g),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------- Misc pieces

  Widget _dismissBg(ThemeData theme) => Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 32.w),
        child: Icon(Icons.visibility_off_rounded,
            size: 22.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
      );

  Widget _emptyState(ThemeData theme) {
    final filtered =
        _selectedGroup != null || _lens != _Lens.all || _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bloodtype_outlined,
                size: 72.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
            SizedBox(height: 16.h),
            Text(
                filtered
                    ? 'Nothing matches this filter'
                    : 'No active requests',
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800)),
            SizedBox(height: 6.h),
            Text(
              filtered
                  ? 'Try a different lens, blood type or search.'
                  : 'All clear for now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
            if (filtered) ...[
              SizedBox(height: 14.h),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _lens = _Lens.all;
                    _selectedGroup = null;
                    _query = '';
                    _searchActive = false;
                  });
                },
                child: const Text('Reset filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showClearDialog(ThemeData theme, List<BloodRequestModel> all) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Clear feed?'),
        content: const Text(
            'This hides all current requests from your view. Your own posts stay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final idToExpiry = <String, DateTime>{
                for (final r in all.where((r) => r.userId != uid))
                  r.id: r.expiryDate.add(const Duration(days: 1)),
              };
              if (idToExpiry.isNotEmpty) {
                await context
                    .read<UserProvider>()
                    .dismissAllRequests(idToExpiry);
              }
              if (mounted) AppSnackbar.success(context, 'Feed cleared');
            },
            child: const Text('Hide others'),
          ),
        ],
      ),
    );
  }
}

/// Pins the single lens row below the app bar. Fixed extent (min == max) keeps
/// it lightweight — the feed, not the chrome, owns the screen.
class _LensHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _LensHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);

  @override
  bool shouldRebuild(covariant _LensHeaderDelegate oldDelegate) => true;
}
