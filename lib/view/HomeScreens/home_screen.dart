import 'package:blood_donation/Provider/auth_provider.dart';
import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/auth%20_screens.dart/login_screen.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/widgets/contribution.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/reusable_email.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  int selectedIndex = -1;

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<UserProvider>().loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 80.h),
            Row(
              children: [
                SizedBox(width: 20),
                CircleAvatar(radius: 30.h),
                SizedBox(width: 10),
                Column(
                  children: [
                    Consumer<UserProvider>(
                      builder:
                          (
                            BuildContext context,
                            UserProvider provider,
                            Widget? child,
                          ) {
                            if (provider.isLoading) {
                              return const CircularProgressIndicator();
                            }
                            final user = provider.user;
                            if (user == null) {
                              return const Text('User not found');
                            }
                            return Text(
                              user.name ?? 'User Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                    ),
                    Text('Donate Blood : off', style: TextStyle(fontSize: 10)),
                  ],
                ),
                SizedBox(width: 120.w),
                Consumer<AuthProviders>(
                  builder: (BuildContext context, auth, Widget? child) {
                    return InkWell(
                      onTap: auth.isLoading
                          ? null
                          : () async {
                              await FirebaseAuth.instance.signOut();

                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              }
                              // if (context.mounted) {
                              //   // Navigator.pop(context);
                              // }
                            },
                      child: Icon(Icons.arrow_back_ios_new_outlined),
                    );
                  },
                ),
                SizedBox(width: 10.w),

                Icon(Icons.notifications_none_outlined),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 28),
              child: CustomTextField(
                focusedBorderColor: Colors.red,
                borderColor: Colors.grey,
                prefixIcon: Icons.search,
                hintText: 'Search blood',
              ),
            ),
            homeHeader(tilte: 'Activity As'),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 2.4,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 10.h),
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                ActivityCard(
                  imagePath: 'assets/images/blood.png',
                  title: 'Blood Donor',
                  subtitle: '120 post',
                ),
                ActivityCard(
                  imagePath: 'assets/images/blod.png',
                  title: 'Blood Recepient',
                  subtitle: '120 post',
                ),
                ActivityCard(
                  imagePath: 'assets/images/drop.png',
                  title: 'Create Post',
                  subtitle: "It's Easy! 3 Step",
                ),
                ActivityCard(
                  imagePath: 'assets/images/drop.png',
                  title: 'Blood Given',
                  subtitle: "It's Easy! 1 Step",
                ),
              ],
            ),
            homeHeader(tilte: 'Blood Group'),

            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),

              shrinkWrap: true,
              padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
              itemCount: bloodGroups.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BloodrequestScreen(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/drop.png',
                                height: 60.h,
                              ),
                              Text(
                                bloodGroups[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            homeHeader(tilte: 'Recently Viewed'),
            homeContainer(bloodGroups: bloodGroups),
            homeContainer(bloodGroups: bloodGroups),
            homeHeader(tilte: 'Our Contribution'),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),

              padding: EdgeInsets.all(20.h),
              itemCount: contributionData.length,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.h,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = contributionData[index];
                return ContributionCard(
                  number: item.number,
                  title: item.title,
                  bgColor: item.bgColor,
                  textColor: item.textColor,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class homeContainer extends StatelessWidget {
  const homeContainer({super.key, required this.bloodGroups});

  final List<String> bloodGroups;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 5.h),
      child: Container(
        height: 130.h,
        // width: 400.w,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 55.h,
                  width: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red),

                    // borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset('assets/images/drop.png', height: 35.h),
                          Text(
                            bloodGroups.first,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    Text(
                      'Emergency B+ Blood Needed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10.h),

                    Row(
                      children: [
                        Icon(Icons.bus_alert_sharp, color: Colors.red),
                        Text('Hospitol Name'),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: Colors.red),
                        Text('12 Feb 2025'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class homeHeader extends StatelessWidget {
  String tilte;
  homeHeader({super.key, required this.tilte});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        child: Text(
          tilte,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const ActivityCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.all(14),
      height: 200,
      // margin: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ICON IMAGE
          Container(
            height: 44,
            width: 44,
            // padding: const EdgeInsets.all(8),
            // decoration: BoxDecoration(),
            child: Image.asset(imagePath, height: 50),
          ),

          const SizedBox(width: 12),

          /// TEXT
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContributionCard extends StatelessWidget {
  final String number;
  final String title;
  final Color bgColor;
  final Color textColor;

  const ContributionCard({
    required this.number,
    required this.title,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
