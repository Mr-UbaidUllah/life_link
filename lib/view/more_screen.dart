import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/ambulance_screen.dart';
import 'package:blood_donation/view/organization_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/user_donate_blood.dart';
import 'package:blood_donation/view/volunteer_screen.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:blood_donation/widgets/menu_tile.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
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
      body: Column(
        children: [
          SizedBox(height: 50.h),
          Text(
            'More',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),

          Divider(),
          SizedBox(height: 40.h),

          Stack(
            clipBehavior: Clip.none,

            children: [
              Padding(
                padding: EdgeInsets.all(20.h),
                child: Container(
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              Positioned(
                top: -10.h,
                right: 150.h,
                child: Consumer2<UserProvider, StorageProvider>(
                  builder: (BuildContext context, users, storage, Widget? child) {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final imageUrl = users.user?.profileImage;

                    return InkWell(
                      onTap: () async {
                        final file = await pickImage();
                        if (file == null) return;

                        final success = await storage.uploadImage(uid, file);

                        if (success) {
                          await users.loadCurrentUser();
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
                                final success = await storage.deleteImage(uid);
                                if (success) {
                                  await users.loadCurrentUser();
                                }
                              }
                            },
                      child: CircleAvatar(
                        radius: 40.h,
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
              ),
              Positioned(
                top: 80.h,
                left: 125.h,
                child: Column(
                  children: [
                    Consumer<UserProvider>(
                      builder:
                          (
                            BuildContext context,
                            UserProvider provider,
                            Widget? child,
                          ) {
                            if (provider.isLoading) {
                              return UserNameShimmer();
                            }
                            final user = provider.user;
                            if (user == null) {
                              return Text('User not found');
                            }
                            return Column(
                              children: [
                                Text(
                                  user.name ?? 'User Name',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  'Blood Group : ${user.bloodGroup}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            );
                          },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                MenuTile(
                  icon: Icons.bloodtype,
                  title: 'Create Blood request',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateRequestScreen(),
                      ),
                    );
                  },
                ),

                MenuTile(
                  icon: Icons.add_box_sharp,
                  title: 'Create Donot Blood ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDonateBlood(),
                      ),
                    );
                  },
                ),
                MenuTile(
                  icon: Icons.bus_alert_outlined,
                  title: 'Blood Donat Oraganization',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrganizationScreen(),
                      ),
                    );
                  },
                ),
                InkWell(
                  child: MenuTile(
                    icon: Icons.bus_alert,
                    title: 'Ambulence',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AmbulanceScreen(),
                        ),
                      );
                    },
                  ),
                ),
                MenuTile(
                  icon: Icons.forward_to_inbox_sharp,
                  title: 'Inbox',
                  onTap: () {},
                ),
                MenuTile(
                  icon: Icons.add_reaction_sharp,
                  title: 'Work as volunteer',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VolunteerScreen(),
                      ),
                    );
                  },
                ),
                MenuTile(
                  icon: Icons.takeout_dining,
                  title: 'Tags',
                  onTap: () {},
                ),
                MenuTile(icon: Icons.settings, title: 'settings', onTap: () {}),
                MenuTile(
                  icon: Icons.favorite,
                  title: 'Donate Us',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
