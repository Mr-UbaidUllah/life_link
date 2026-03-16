import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AmbulenceCard extends StatelessWidget {
  final String image;
  final String name;
  final String address;
  final String phone;

  const AmbulenceCard({
    super.key,
    required this.image,
    required this.name,
    required this.address,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6.w,
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      // Image with loading indicator
                      Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Image.network(
                            image,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.emergency_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 30.sp),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14.sp, color: theme.colorScheme.primary),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                SizedBox(width: 4.w),
                                Text(
                                  phone,
                                  style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Action Button
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.call_rounded, color: theme.colorScheme.primary, size: 18.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Call',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
