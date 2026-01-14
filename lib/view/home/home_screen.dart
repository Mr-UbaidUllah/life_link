import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:blood_donation/Provider/auth_provider.dart';
import 'package:blood_donation/Provider/bloodRequest_provider.dart';
import 'package:blood_donation/Provider/storage_provider.dart';
import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/specific_Bloodgroup_screen.dart';
import 'package:blood_donation/widgets/contribution.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/image_picker.dart';
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
  int selectedIndex = 1;

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
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // SizedBox(height: 80.h),
              Row(
                children: [
                  SizedBox(width: 20),
                  Consumer2<StorageProvider, UserProvider>(
                    // used for the 2 providers
                    builder: (context, storage, userProvider, child) {
                      final imageUrl = userProvider.user?.profileImage;
                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      return InkWell(
                        onTap: () async {
                          final file = await pickImage();
                          if (file == null) return;

                          final success = await storage.uploadImage(uid, file);
                          if (success) {
                            await userProvider
                                .loadCurrentUser(); //  refresh user
                          }
                        },
                        onLongPress: imageUrl == null
                            ? null
                            : () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Remove Profile Image'),
                                    content: const Text(
                                      'Do you want to delete your profile image?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  final success = await storage.deleteImage(
                                    uid,
                                  );
                                  if (success) {
                                    await userProvider.loadCurrentUser();
                                  }
                                }
                              },
                        child: CircleAvatar(
                          radius: 30.h,
                          backgroundImage: imageUrl != null
                              ? NetworkImage(imageUrl)
                              : null,
                          child: imageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      );
                    },
                  ),

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
                      Consumer<UserProvider>(
                        builder:
                            (
                              BuildContext context,
                              UserProvider provider,
                              Widget? child,
                            ) {
                              return Text(
                                provider.isWilling
                                    ? 'Donate Blood : On'
                                    : 'Donate Blood : OFF',
                                style: TextStyle(fontSize: 10),
                              );
                            },
                      ),
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
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 21,
              //     vertical: 28,
              //   ),
              //   child: CustomTextField(
              //     focusedBorderColor: Colors.red,
              //     borderColor: Colors.grey,
              //     prefixIcon: Icons.search,
              //     hintText: 'Search blood',
              //     onChanged: (val) {
              //       Provider.of<BloodrequestProvider>(
              //         context,
              //         listen: false,
              //       ).searchByBlood(val);
              //     },
              //   ),
              // ),
              // Consumer<BloodrequestProvider>(
              //   builder: (context, provider, _) {
              //     return StreamBuilder(
              //       stream: provider.requests,
              //       builder: (context, snapshot) {
              //         if (!snapshot.hasData) {
              //           return const CircularProgressIndicator();
              //         }

              //         final requests = snapshot.data!;

              //         return ListView.builder(
              //           shrinkWrap: true,
              //           itemCount: requests.length,
              //           itemBuilder: (context, index) {
              //             final req = requests[index];

              //             return Card(
              //               child: ListTile(
              //                 title: Text(req.title),
              //                 subtitle: Text("${req.bloodGroup} • ${req.city}"),
              //                 trailing: Text("${req.bags} Bags"),
              //               ),
              //             );
              //           },
              //         );
              //       },
              //     );
              //   },
              // ),
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
                itemCount: bloodGroups.length,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
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
                            builder: (context) => SpecificBloodgroupScreen(
                              bloodGroup: bloodGroups[index],
                            ),
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
              Consumer<BloodrequestProvider>(
                builder: (context, provider, _) {
                  return StreamBuilder<List<BloodRequestModel>>(
                    stream: provider.requests,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No requests found"));
                      }
                      // provider.setRequests(snapshot.data!);
                      final requests = snapshot.data!;
                      final int itemCount = requests.length > 2
                          ? 2
                          : requests.length;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          final req = requests[index];

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BloodrequestScreen(),
                                ),
                              );
                            },
                            child: homeContainer(
                              bloodGroup: req.bloodGroup,
                              title: req.title,
                              hospital: req.hospital,
                              date: req.createdAt.toLocal().toString().split(
                                ' ',
                              )[0],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),

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
      ),
    );
  }
}

class homeContainer extends StatelessWidget {
  const homeContainer({
    super.key,
    required this.bloodGroup,
    required this.title,
    required this.hospital,
    required this.date,
  });

  final String bloodGroup;
  final String title;
  final String hospital;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 5.h),
      child: Container(
        height: 130.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),

            /// BLOOD DROP
            Container(
              height: 55.h,
              width: 55.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/images/drop.png', height: 35.h),
                  Text(
                    bloodGroup,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 15.w),

            /// DETAILS
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 5.w),
                    Text(hospital, style: TextStyle(fontSize: 15.sp)),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 5.w),
                    Text(date),
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
          SizedBox(
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
    super.key,
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
