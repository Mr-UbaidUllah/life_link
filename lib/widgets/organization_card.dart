import 'package:blood_donation/models/organization_model.dart';
import 'package:blood_donation/view/organization_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrganizationCard extends StatelessWidget {
  final OrganizationModel organization;

  const OrganizationCard({
    super.key,
    required this.organization,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String getTypeLabel() {
      switch (organization.type) {
        case OrganizationType.hospital: return 'Hospital';
        case OrganizationType.bloodBank: return 'Blood Bank';
        case OrganizationType.ngo: return 'NGO';
        case OrganizationType.clinic: return 'Clinic';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrganizationDetailsScreen(organization: organization),
          ),
        );
      },
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6.w,
                  color: organization.isVerified ? Colors.blue : theme.colorScheme.primary,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Row(
                      children: [
                        // Image with Hero
                        Hero(
                          tag: 'org_image_${organization.id}',
                          child: Container(
                            width: 75.w,
                            height: 75.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.r),
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.r),
                              child: Image.network(
                                organization.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.business_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 30.sp),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      organization.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (organization.isVerified)
                                    Padding(
                                      padding: EdgeInsets.only(left: 4.w),
                                      child: Icon(Icons.verified_rounded, color: Colors.blue, size: 16.sp),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                getTypeLabel(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      '${organization.city}, ${organization.country}',
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
                        SizedBox(width: 8.w),
                        // Rating Badge
                        if (organization.rating > 0)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 20.sp),
                              Text(
                                organization.rating.toString(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
      ),
    );
  }
}
