import 'package:blood_donation/models/organization_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganizationDetailsScreen extends StatelessWidget {
  final OrganizationModel organization;

  const OrganizationDetailsScreen({super.key, required this.organization});

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250.h,
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
                tag: 'org_image_${organization.id}',
                child: Image.network(
                  organization.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.business_rounded, size: 80.sp, color: theme.colorScheme.primary.withValues(alpha: 0.2)),
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
                            Row(
                              children: [
                                Text(
                                  organization.name,
                                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                                ),
                                if (organization.isVerified) ...[
                                  SizedBox(width: 8.w),
                                  Icon(Icons.verified_rounded, color: Colors.blue, size: 20.sp),
                                ],
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${organization.city}, ${organization.country}',
                              style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                      if (organization.rating > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
                              SizedBox(width: 4.w),
                              Text(
                                organization.rating.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  Row(
                    children: [
                      _buildTypeChip(theme, getTypeLabel()),
                      SizedBox(width: 10.w),
                      if (organization.joinedAt != null)
                        Text(
                          'Partner since ${organization.joinedAt!.year}',
                          style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 30.h),
                  Text('About', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  Text(
                    organization.description.isEmpty 
                      ? 'No description provided.' 
                      : organization.description,
                    style: TextStyle(
                      fontSize: 14.sp, 
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  Text('Contact Information', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16.h),
                  
                  _buildContactItem(theme, Icons.location_on_rounded, 'Address', organization.address),
                  _buildContactItem(theme, Icons.phone_rounded, 'Phone', organization.phone, onTap: () => _makeCall(organization.phone)),
                  if (organization.email.isNotEmpty)
                    _buildContactItem(theme, Icons.email_rounded, 'Email', organization.email),
                  if (organization.website.isNotEmpty)
                    _buildContactItem(theme, Icons.language_rounded, 'Website', organization.website, onTap: () => _launchURL(organization.website)),
                  
                  SizedBox(height: 100.h), 
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 20.sp),
                label: const Text('Send Message'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _makeCall(organization.phone),
                icon: Icon(Icons.call_rounded, color: Colors.white, size: 20.sp),
                label: Text(
                  'Call Now',
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

  Widget _buildTypeChip(ThemeData theme, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildContactItem(ThemeData theme, IconData icon, String title, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 20.sp, color: theme.colorScheme.primary),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  SizedBox(height: 2.h),
                  Text(
                    value, 
                    style: TextStyle(
                      fontSize: 14.sp, 
                      fontWeight: FontWeight.w600,
                      decoration: onTap != null ? TextDecoration.underline : null,
                      decorationColor: theme.colorScheme.primary,
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
