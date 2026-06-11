import 'package:blood_donation/models/organization_model.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/view/add_organization_screen.dart';
import 'package:blood_donation/widgets/organization_card.dart';
import 'package:blood_donation/widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  // Cache the stream so returning from the add screen (which notifies the
  // provider) doesn't resubscribe and flash the shimmer.
  late final Stream<List<OrganizationModel>> _orgStream;

  @override
  void initState() {
    super.initState();
    _orgStream = context.read<OrganizationProvider>().requests;
  }

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
          'Organizations',
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
                  color: Colors.black.withValues(alpha: 0.03),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Discover partner organizations supporting blood donation causes.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<OrganizationProvider>(
              builder: (context, _, __) {
                return StreamBuilder<List<OrganizationModel>>(
                  stream: _orgStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ShimmerList(
                        itemCount: 5,
                        itemBuilder: (_, __) => const ContactCardSkeleton(),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 80.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                            SizedBox(height: 16.h),
                            Text(
                              "No organizations found",
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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

                        return OrganizationCard(
                          image: req.image,
                          name: req.name,
                          address: req.address,
                          phone: req.phone,
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
            MaterialPageRoute(builder: (_) => const AddOrganizationScreen()),
          );
        },
        child: Icon(Icons.add_rounded, size: 30.sp, color: Colors.white),
      ),
    );
  }
}
