import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/view/add_ambulence.dart';
import 'package:blood_donation/widgets/ambulence_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Emergency Ambulance',
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
      body: Column(
        children: [
          // Info Banner
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
                  child: Icon(Icons.emergency_rounded, color: theme.colorScheme.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Quickly find and contact nearby ambulance services for emergencies.',
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
            child: Consumer<AmbulanceProvider>(
              builder: (context, ambulance, _) {
                return StreamBuilder<List<AmbulanceModel>>(
                  stream: ambulance.ambulanceRequest,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Something went wrong', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bus_alert_rounded, size: 80.sp, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                            SizedBox(height: 16.h),
                            Text(
                              "No ambulances found",
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                          ],
                        ),
                      );
                    }
                    final requests = snapshot.data!;

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(20.w),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];

                        return AmbulenceCard(
                          image: req.imageUrl,
                          name: req.hospitalName,
                          address: req.address,
                          phone: req.phoneNumber,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAmbulence()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
    );
  }
}
