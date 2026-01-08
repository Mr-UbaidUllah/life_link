import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:blood_donation/Models/user_model.dart';
import 'package:blood_donation/Provider/bloodRequest_provider.dart';
import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/HomeScreens/home_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/dropdownheader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),

          /// TITLE
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                'Search',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          SliverToBoxAdapter(child: const Divider()),

          /// SEARCH FIELD
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
              child: CustomTextField(
                focusedBorderColor: Colors.red,
                prefixIcon: Icons.search,
                hintText: 'Search Blood',
              ),
            ),
          ),

          /// BLOOD GROUP HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Dropdownheader(name: 'Blood Group'),
            ),
          ),

          /// BLOOD GROUP GRID
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 20.h),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final isSelected = selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/images/drop.png', height: 60.h),
                        Text(
                          bloodGroups[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: bloodGroups.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
            ),
          ),

          /// RECENT REQUEST HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Dropdownheader(name: 'Recent Blood Request'),
            ),
          ),

          /// RECENT REQUEST LIST
          SliverToBoxAdapter(
            child: Consumer<BloodrequestProvider>(
              builder: (context, provider, _) {
                return StreamBuilder<List<BloodRequestModel>>(
                  stream: provider.requests,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data!.take(2).toList();

                    return Column(
                      children: requests.map((req) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailsScreen(request: req),
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
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),

          /// DONORS HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Dropdownheader(name: 'Recent Blood Donor'),
            ),
          ),

          /// DONORS LIST (CORRECT SLIVER)
          Consumer<UserProvider>(
            builder: (context, provider, child) {
              return StreamBuilder<List<UserModel>>(
                stream: provider.donors,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final donors = snapshot.data!;

                  if (donors.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No donors found')),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final user = donors[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(user.name ?? ''),
                        subtitle: Text('${user.bloodGroup} | ${user.phone}'),
                      );
                    }, childCount: donors.length),
                  );
                },
              );
            },
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
        ],
      ),
    );
  }
}
