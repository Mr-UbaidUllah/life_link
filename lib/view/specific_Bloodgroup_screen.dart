import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodGroup_provider.dart';
import 'package:blood_donation/widgets/home_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class SpecificBloodgroupScreen extends StatelessWidget {
  final String? bloodGroup;

  const SpecificBloodgroupScreen({super.key, this.bloodGroup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          bloodGroup ?? "All Requests",
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
        ),
      ),
      body: Consumer<BloodGroupRequestProvider>(
        builder: (context, provider, _) {
          return StreamBuilder<List<BloodRequestModel>>(
            stream: provider.postsByBloodGroup(bloodGroup!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bloodtype_outlined, size: 80.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      SizedBox(height: 16.h),
                      Text(
                        "No $bloodGroup requests found",
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final requests = snapshot.data!;

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];

                  return HomeContainer(
                    bloodGroup: req.bloodGroup,
                    title: req.title,
                    hospital: req.hospital,
                    date: req.createdAt.toLocal().toString().split(' ')[0],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
