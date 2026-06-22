import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/provider/blood_request_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/profile/profile_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blood_donation/utils/phone_launcher.dart';
import 'package:provider/provider.dart';

class PostDetailsScreen extends StatefulWidget {
  final BloodRequestModel request;

  const PostDetailsScreen({super.key, required this.request});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<UserProvider>().loadUserById(widget.request.userId);
      }
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final ok = await launchDialer(phoneNumber);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == widget.request.userId;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isOwner)
            IconButton(
              onPressed: () => _showCancelDialog(context, theme),
              icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.primary),
              tooltip: 'Cancel Request',
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          final request = widget.request;
          final postUser = provider.postUser;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOwner)
                        Container(
                          margin: EdgeInsets.only(bottom: 15.h),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.info, size: 20),
                              SizedBox(width: 10.w),
                              Text(
                                'This is your request.',
                                style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                      /// HEADER SECTION
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 80.r,
                                  width: 80.r,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Icon(Icons.water_drop_rounded, color: theme.colorScheme.primary, size: 50.sp),
                                Positioned(
                                  child: Text(
                                    request.bloodGroup,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              request.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                SizedBox(width: 4.w),
                                Text(
                                  "Posted on ${request.createdAt.toLocal().toString().split(' ')[0]}",
                                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12.sp),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      /// CONTACT PERSON CARD
                      Text(
                        'Contact Person',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileDetailsScreen(userId: request.userId),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25.r,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                backgroundImage: postUser?.profileImage != null ? NetworkImage(postUser!.profileImage!) : null,
                                child: postUser?.profileImage == null ? Icon(Icons.person_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)) : null,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.contactName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: theme.colorScheme.onSurface),
                                    ),
                                    Text(
                                      'View Profile',
                                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 12.sp, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      /// INFO SECTION
                      Text(
                        'Hospital & Location',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildInfoItem(theme, Icons.local_hospital_rounded, 'Hospital', request.hospital),
                            Divider(height: 24, color: theme.dividerColor.withValues(alpha: 0.05)),
                            _buildInfoItem(theme, Icons.location_on_rounded, 'Location', "${request.city}, ${request.country}"),
                            Divider(height: 24, color: theme.dividerColor.withValues(alpha: 0.05)),
                            _buildInfoItem(theme, Icons.bloodtype_rounded, 'Quantity Required', "${request.bags} Bag(s)"),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      /// DESCRIPTION SECTION
                      Text(
                        'Reason for Requirement',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          request.reason.isNotEmpty ? request.reason : 'No specific reason provided.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 14.sp, height: 1.5),
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              /// BOTTOM ACTION BUTTONS
              if (!isOwner)
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _makeCall(request.phone),
                          icon: const Icon(Icons.call_rounded, color: Colors.white),
                          label: const Text('Call Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Always message the request's OWNER. Key the chat
                            // off request.userId (authoritative) rather than the
                            // shared postUser.uid, which can be stale/null and
                            // would otherwise open a chat with the wrong person.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  name: postUser?.name ?? request.contactName,
                                  receiverId: request.userId,
                                  imageUrl: postUser?.profileImage,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message_rounded, color: Colors.white),
                          label: const Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isOwner)
                Container(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCancelDialog(context, theme),
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                      label: const Text('Found Donor / Close Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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

  void _showCancelDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Close Request?', style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text('If you found a donor or want to stop this request, it will be hidden from other users.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('No', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
          TextButton(
            onPressed: () async {
              // Capture provider + navigator from the SCREEN context (still mounted)
              // BEFORE popping — popping deactivates the dialog's own context, and
              // reading providers/Navigator off a deactivated context throws
              // "Looking up a deactivated widget's ancestor is unsafe".
              final provider = context.read<BloodrequestProvider>();
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext); // close the dialog
              await provider.updateStatus(widget.request.id, 'closed');
              if (mounted) navigator.pop(); // close the details screen
            },
            child: Text('Yes, Close it', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12.sp)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}
