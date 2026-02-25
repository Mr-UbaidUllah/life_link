import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/provider/volunteer_provider.dart';
import 'package:blood_donation/view/add_volunteer_screen.dart';
import 'package:blood_donation/widgets/volunteer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Work as a Volunteer')),

      body: Padding(
        padding: EdgeInsets.all(30.h),
        child: Column(
          children: [
            Container(
              height: 200.h,
              width: 300.w,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20.sp),
              ),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Text(
                      'If you wish You can join with us as a volunteer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.h,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(18.h),
                      child: Container(
                        height: 50.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.sp),
                        ),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVolunteerScreen(),
                                ),
                              );
                            },
                            child: Text('Join Now'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            Divider(),
            SizedBox(height: 20.h),
            Text(
              'They all work as a Volunteers.They work hard to make it success',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 70.h),

            Consumer<VolunteerProvider>(
              builder:
                  (
                    BuildContext context,
                    VolunteerProvider volunt,
                    Widget? child,
                  ) {
                    return StreamBuilder<List<VolunteerModel>>(
                      stream: volunt.volunteerRequests,
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<VolunteerModel>> snapshot,
                          ) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return const Center(
                                child: Text('Something went wrong'),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text('No Volunteer  found'),
                              );
                            }
                            final req = snapshot.data!;
                            return Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: req.length,
                                itemBuilder: (BuildContext context, index) {
                                  final requests = req[index];
                                  return VolunteerCard(
                                    image: requests.imageUrl,
                                    name: requests.name,
                                    description: requests.workDescription,
                                  );
                                },
                              ),
                            );
                          },
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
