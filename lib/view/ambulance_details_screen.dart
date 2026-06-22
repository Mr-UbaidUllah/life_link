import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AmbulanceDetailsScreen extends StatelessWidget {
  final AmbulanceModel ambulance;

  const AmbulanceDetailsScreen({super.key, required this.ambulance});

  Future<void> _makeCall(String phoneNumber) async {
    await launchDialer(phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String getAmbulanceTypeLabel() {
      switch (ambulance.type) {
        case AmbulanceType.cardiac: return 'Cardiac (ICU)';
        case AmbulanceType.basic: return 'Basic Life Support';
        case AmbulanceType.neonatal: return 'Neonatal (NICU)';
        case AmbulanceType.oxygen: return 'Oxygen Support';
      }
    }

    // Capabilities typical of the selected ambulance type. Derived from the one
    // real attribute the registrant entered (type) instead of showing an
    // identical hardcoded list for every vehicle.
    List<String> getTypicalCapabilities() {
      switch (ambulance.type) {
        case AmbulanceType.cardiac:
          return ['ICU Equipment', 'Cardiac Monitor', 'Defibrillator', 'Trained Paramedics', 'Oxygen Supply'];
        case AmbulanceType.neonatal:
          return ['Incubator', 'Neonatal Ventilator', 'Trained Paramedics', 'Oxygen Supply'];
        case AmbulanceType.oxygen:
          return ['Oxygen Cylinders', 'Ventilator Support', 'Trained Attendant'];
        case AmbulanceType.basic:
          return ['First Aid Kit', 'Oxygen Supply', 'Stretcher', 'Trained Driver'];
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header with Image
          SliverAppBar(
            expandedHeight: 280.h,
            pinned: true,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'ambulance_image_${ambulance.id}',
                child: Image.network(
                  ambulance.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.emergency_rounded, size: 80.sp, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ambulance.hospitalName,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              ambulance.ambulanceName,
                              style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Rs. ${ambulance.basePrice}',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Type & availability. No rating chip: there is no review
                  // system, so the model's default 4.5 was a fabricated score.
                  Row(
                    children: [
                      _buildChip(theme, Icons.medical_services_rounded, getAmbulanceTypeLabel(), theme.colorScheme.primary),
                      const Spacer(),
                      _buildAvailabilityTag(ambulance.isAvailable),
                    ],
                  ),
                  
                  SizedBox(height: 30.h),
                  Text('Service Details', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  
                  _buildDetailItem(theme, Icons.location_on_rounded, 'Address', ambulance.address),
                  _buildDetailItem(theme, Icons.phone_rounded, 'Emergency Contact', ambulance.phoneNumber),

                  SizedBox(height: 30.h),
                  Text('Typical Capabilities', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6.h),
                  Text(
                    'Based on the registered ambulance type — confirm specifics when you call.',
                    style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: getTypicalCapabilities()
                        .map((f) => _buildFeatureTag(theme, f))
                        .toList(),
                  ),
                  
                  SizedBox(height: 100.h), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5)),
          ],
        ),
        // Call only. The previous map IconButton did nothing (no coordinates
        // are collected), and "Book Now" implied a booking flow that doesn't
        // exist — this just dials the emergency contact.
        child: ElevatedButton.icon(
          onPressed: () => _makeCall(ambulance.phoneNumber),
          icon: const Icon(Icons.call_rounded, color: Colors.white),
          label: Text(
            'Call Ambulance',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            minimumSize: Size(double.infinity, 54.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(ThemeData theme, IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTag(bool available) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: (available ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        available ? 'Available' : 'Busy',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: available ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                SizedBox(height: 2.h),
                Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(ThemeData theme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
      ),
    );
  }
}
