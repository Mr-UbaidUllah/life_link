import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DonationInfoScreen extends StatelessWidget {
  const DonationInfoScreen({super.key});

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
          'Donation Info',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              theme,
              'Why Donate Blood?',
              'A single donation can save up to three lives. Your blood helps patients undergoing surgery, cancer treatment, or recovering from accidents.',
              Icons.volunteer_activism,
            ),
            SizedBox(height: 20.h),
            _buildSection(
              theme,
              'Eligibility Criteria',
              '• Age: 18-65 years old.\n• Weight: At least 50 kg.\n• Health: You should be in good general health at the time of donation.',
              Icons.fact_check,
            ),
            SizedBox(height: 20.h),
            _buildSection(
              theme,
              'Preparation Tips',
              '• Drink plenty of water.\n• Have a healthy meal before donating.\n• Get a good night\'s sleep.\n• Avoid alcohol 24 hours before.',
              Icons.lightbulb,
            ),
            SizedBox(height: 20.h),
            _buildSection(
              theme,
              'After Donation',
              '• Rest for 5-10 minutes.\n• Drink extra fluids for the next 48 hours.\n• Avoid heavy lifting or intense exercise for 24 hours.',
              Icons.healing,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
