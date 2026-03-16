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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
        ),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
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
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Browse all urgent blood requests and help save lives.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer2<BloodrequestProvider, UserProvider>(
              builder: (context, bloodProvider, userProvider, _) {
                final dismissedIds = userProvider.user?.dismissedRequests ?? [];

                return StreamBuilder<List<BloodRequestModel>>(
                  stream: bloodProvider.requests,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    final requests = snapshot.data!.where((req) {
                      final isMine = req.userId == currentUserId;
                      final isDismissed = dismissedIds.contains(req.id);
                      return isMine || !isDismissed;
                    }).toList();

                    if (requests.isEmpty) {
                      return _buildEmptyState(theme);
                    }

                    return ListView.builder(
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
                            color: theme.colorScheme.primary.withOpacity(0.1),
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
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bloodtype_outlined, size: 80.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          SizedBox(height: 16.h),
          Text(
            "No active requests",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          SizedBox(height: 8.h),
          Text(
            "Everything is currently stable.",
            style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
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
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
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
