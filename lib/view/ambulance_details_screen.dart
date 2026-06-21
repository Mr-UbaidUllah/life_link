import 'package:blood_donation/models/ambulance_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulanceDetailsScreen extends StatelessWidget {
  final AmbulanceModel ambulance;

  const AmbulanceDetailsScreen({super.key, required this.ambulance});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
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

                  // Rating & Type Row
                  Row(
                    children: [
                      _buildChip(theme, Icons.star_rounded, ambulance.rating.toString(), Colors.amber),
                      SizedBox(width: 10.w),
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
                  _buildDetailItem(theme, Icons.info_outline_rounded, 'Service Area', 'City Wide (24/7)'),
                  
                  SizedBox(height: 30.h),
                  Text('Features', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      _buildFeatureTag(theme, 'Air Conditioned'),
                      _buildFeatureTag(theme, 'Ventilator Support'),
                      _buildFeatureTag(theme, 'Trained Paramedics'),
                      _buildFeatureTag(theme, 'Oxygen Supply'),
                    ],
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
        child: Row(
          children: [
            Container(
              height: 54.h,
              width: 54.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: IconButton(
                icon: Icon(Icons.map_rounded, color: theme.colorScheme.primary),
                onPressed: () {},
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(ambulance.phoneNumber),
                icon: const Icon(Icons.call_rounded, color: Colors.white),
                label: Text(
                  'Book Now',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
          ],
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
        color: available ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        available ? 'Available' : 'Busy',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: available ? Colors.green : Colors.orange,
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
