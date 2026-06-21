import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/view/ambulance_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class AmbulenceCard extends StatelessWidget {
  final AmbulanceModel ambulance;

  const AmbulenceCard({
    super.key,
    required this.ambulance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color getStatusColor() {
      return ambulance.isAvailable ? Colors.green : Colors.orange;
    }

    String getAmbulanceTypeLabel() {
      switch (ambulance.type) {
        case AmbulanceType.cardiac: return 'Cardiac (ICU)';
        case AmbulanceType.basic: return 'Basic Life Support';
        case AmbulanceType.neonatal: return 'Neonatal (NICU)';
        case AmbulanceType.oxygen: return 'Oxygen Support';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image and Availability Badge
                Stack(
                  children: [
                    Container(
                      width: 85.w,
                      height: 85.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Hero(
                          tag: 'ambulance_image_${ambulance.id}',
                          child: Image.network(
                            ambulance.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.emergency_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 35.sp),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: getStatusColor(),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          ambulance.isAvailable ? 'AVAILABLE' : 'BUSY',
                          style: TextStyle(color: Colors.white, fontSize: 8.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ambulance.hospitalName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Rs. ${ambulance.basePrice}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        getAmbulanceTypeLabel(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14.sp, color: Colors.amber),
                          SizedBox(width: 2.w),
                          Text(
                            ambulance.rating.toString(),
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${ambulance.reviews} reviews)',
                            style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              ambulance.address,
                              style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.05)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AmbulanceDetailsScreen(ambulance: ambulance),
                        ),
                      );
                    },
                    icon: Icon(Icons.info_outline_rounded, size: 18.sp),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri url = Uri.parse('tel:${ambulance.phoneNumber}');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    icon: Icon(Icons.call_rounded, size: 18.sp, color: Colors.white),
                    label: const Text('Call Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
