import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/userPost_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/msg_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userId;

  const ProfileDetailsScreen({super.key, required this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();

  /// RED BUTTON
  static Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 120.w,
      height: 40.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(text),
      ),
    );
  }

  /// OUTLINE BUTTON
  static Widget _outlineButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 120.w,
      height: 40.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(text, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  /// SOCIAL ICON
  static Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.blue),
    );
  }
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  @override
  void initState() {
    super.initState();

    // Load user data
    Future.microtask(() {
      context.read<UserProvider>().loadUserById(widget.userId);
    });
  }

  static Widget _infoRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Match TabBar tabs
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: const BackButton(color: Colors.black),
          title: const Text(
            "Profile Details",
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Consumer<UserProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = provider.postUser;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 10.h),

                  /// PROFILE IMAGE
                  CircleAvatar(
                    radius: 45,
                    backgroundImage: user.profileImage != null
                        ? NetworkImage(user.profileImage!)
                        : null,
                  ),

                  SizedBox(height: 12.h),

                  /// NAME
                  Text(
                    user.name.toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  SizedBox(height: 4.h),

                  /// BLOOD GROUP
                  Text(
                    user.bloodGroup.toString(),
                    style: TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 16.h),

                  /// CHAT & CALL BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProfileDetailsScreen._actionButton(
                        text: "Chat Now",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                name: user.name.toString(),
                                receiverId: user.uid,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 12.w),
                      ProfileDetailsScreen._outlineButton(
                        text: "Call",
                        onTap: () {},
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  /// TAB BAR
                  const TabBar(
                    indicatorColor: Colors.red,
                    indicatorWeight: 2,
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: "About"),
                      Tab(text: "Create Ads"),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  /// TAB CONTENT
                  SizedBox(
                    height: 420.h,
                    child: TabBarView(
                      children: [
                        /// ABOUT TAB
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // _infoRow("Age", "30"),
                                  // _infoRow("Gender", "Male"),
                                  _infoRow("City", user.city.toString()),
                                  _infoRow("Country", user.country.toString()),
                                  _infoRow("Mobile", user.phone.toString()),
                                  _infoRow("Email", "demo@email.com"),
                                ],
                              ),
                            ),

                            SizedBox(height: 16.h),

                            Text(
                              "About User",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 8.h),

                            const Text(
                              "Libero tempore, cum soluta nobis est eligendi optio "
                              "cumque nihil impedit quo minus id quod maxime placeat "
                              "facere possimus.",
                              style: TextStyle(color: Colors.grey),
                            ),

                            SizedBox(height: 20.h),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ProfileDetailsScreen._socialIcon(
                                  Icons.facebook,
                                ),
                                ProfileDetailsScreen._socialIcon(
                                  Icons.alternate_email,
                                ),
                                ProfileDetailsScreen._socialIcon(Icons.send),
                                ProfileDetailsScreen._socialIcon(
                                  Icons.business,
                                ),
                              ],
                            ),
                          ],
                        ),

                        /// CREATE ADS TAB (show only user posts)
                        /// CREATE ADS TAB (show only user posts)
                        Consumer<UserPostsProvider>(
                          builder: (context, provider, _) {
                            return Column(
                              children: [
                                // ADD POST BUTTON
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Navigate to the screen where user can create a post
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateRequestScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add Post"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),

                                // POSTS LIST
                                Expanded(
                                  child: StreamBuilder<List<BloodRequestModel>>(
                                    stream: provider.posts(widget.userId),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return const Center(
                                          child: Text("No requests found"),
                                        );
                                      }

                                      final requests = snapshot.data!;

                                      return ListView.builder(
                                        itemCount: requests.length,
                                        itemBuilder: (context, index) {
                                          final req = requests[index];
                                          return InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BloodrequestScreen(),
                                                ),
                                              );
                                            },
                                            child: HomeContainer(
                                              bloodGroup: req.bloodGroup,
                                              title: req.title,
                                              hospital: req.hospital,
                                              date: req.createdAt
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[0],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 20.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
