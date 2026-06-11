import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class BloodrequestScreen extends StatefulWidget {
  const BloodrequestScreen({super.key});

  @override
  State<BloodrequestScreen> createState() => _BloodrequestScreenState();
}

class _BloodrequestScreenState extends State<BloodrequestScreen> {
  static const List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  // null == "All"
  String? _selectedGroup;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<UserProvider>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
              )
            : null,
        centerTitle: true,
        title: Text(
          'Blood Requests',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          Consumer<BloodrequestProvider>(
            builder: (context, bloodProvider, _) {
              return StreamBuilder<List<BloodRequestModel>>(
                stream: bloodProvider.requests,
                builder: (context, snapshot) {
                  final allRequests = snapshot.data ?? [];
                  return IconButton(
                    onPressed: allRequests.isEmpty
                        ? null
                        : () => _showClearRequestsDialog(context, theme, allRequests),
                    icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.primary),
                    tooltip: 'Clear All Requests',
                  );
                },
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Consumer2<BloodrequestProvider, UserProvider>(
        builder: (context, bloodProvider, userProvider, _) {
          final dismissedIds = userProvider.user?.dismissedRequests ?? [];
          final userGroup = userProvider.user?.bloodGroup;

          return StreamBuilder<List<BloodRequestModel>>(
            stream: bloodProvider.requests,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
              }

              // Requests the user is allowed to see (own posts + non-dismissed).
              final visible = (snapshot.data ?? []).where((req) {
                final isMine = req.userId == currentUserId;
                final isDismissed = dismissedIds.contains(req.id);
                return isMine || !isDismissed;
              }).toList();

              // Apply the selected blood-group filter.
              var requests = _selectedGroup == null
                  ? visible
                  : visible.where((r) => r.bloodGroup == _selectedGroup).toList();

              // With no explicit filter, surface requests matching the user first.
              if (_selectedGroup == null && userGroup != null && userGroup.isNotEmpty) {
                requests = [...requests]..sort((a, b) {
                    final aMatch = a.bloodGroup == userGroup ? 0 : 1;
                    final bMatch = b.bloodGroup == userGroup ? 0 : 1;
                    return aMatch.compareTo(bMatch);
                  });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCountBanner(theme, visible.length),
                  _buildFilterChips(theme, userGroup),
                  Expanded(
                    child: requests.isEmpty
                        ? _buildEmptyState(theme)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              final req = requests[index];
                              final isMine = req.userId == currentUserId;

                              return Dismissible(
                                key: Key(req.id),
                                direction: isMine ? DismissDirection.none : DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20.w),
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.delete_outline, color: theme.colorScheme.primary),
                                ),
                                onDismissed: isMine ? null : (direction) {
                                  userProvider.dismissRequest(req.id);
                                },
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailsScreen(request: req),
                                      ),
                                    );
                                  },
                                  child: HomeContainer(
                                    bloodGroup: req.bloodGroup,
                                    title: req.title,
                                    hospital: req.hospital,
                                    date: req.createdAt.toLocal().toString().split(' ')[0],
                                    ownerId: req.userId,
                                    matchesUser: userGroup != null && userGroup.isNotEmpty && req.bloodGroup == userGroup,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCountBanner(ThemeData theme, int openCount) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.bloodtype_rounded, color: theme.colorScheme.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: '$openCount ',
                    style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 14.sp),
                  ),
                  TextSpan(text: openCount == 1 ? 'open request' : 'open requests'),
                  const TextSpan(text: ' — swipe to dismiss, tap to help.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, String? userGroup) {
    final options = <String?>[null, ..._bloodGroups];
    return SizedBox(
      height: 46.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final value = options[index];
          final isSelected = _selectedGroup == value;
          final isUserGroup = value != null && value == userGroup;
          final label = value ?? 'All';

          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: GestureDetector(
              onTap: () => setState(() => _selectedGroup = value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (isUserGroup) ...[
                      SizedBox(width: 5.w),
                      Icon(
                        Icons.star_rounded,
                        size: 13.sp,
                        color: isSelected ? Colors.white : theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final filtered = _selectedGroup != null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bloodtype_outlined, size: 80.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
          SizedBox(height: 16.h),
          Text(
            filtered ? 'No $_selectedGroup requests' : 'No active requests',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          SizedBox(height: 8.h),
          Text(
            filtered ? 'Try a different blood group.' : 'Everything is currently stable.',
            style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          if (filtered) ...[
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => setState(() => _selectedGroup = null),
              child: Text('Show all requests', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  void _showClearRequestsDialog(BuildContext context, ThemeData theme, List<BloodRequestModel> allRequests) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text('Clear All Requests?', style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text(
            'This action will hide all current blood requests from your view. Your own requests will remain visible for you to manage.',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final idsToDismiss = allRequests
                    .where((req) => req.userId != currentUserId)
                    .map((e) => e.id)
                    .toList();

                if (idsToDismiss.isNotEmpty) {
                  await context.read<UserProvider>().dismissAllRequests(idsToDismiss);
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feed cleared (Your posts remain)'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: const Text('Hide Others', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
