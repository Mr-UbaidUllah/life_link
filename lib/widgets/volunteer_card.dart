import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VolunteerCard extends StatelessWidget {
  final String image;
  final String name;
  final String description;

  const VolunteerCard({
    super.key,
    required this.image,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.only(bottom: 16.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Image (Responsive Width using .w)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                image,
                width: 55.w,
                height: 55.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 55.w, height: 55.w, color: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // 2. Text Details (Expanded to take safe remaining space)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevents vertical overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_4_outlined, size: 16.sp, color: Colors.red),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Prevents text overflow
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // Prevents text overflow
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 3. Button (Responsive Width using .w)
            SizedBox(
              width: 85.w,
              height: 34.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.zero, // Prevents text clipping inside button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () {},
                child: Text(
                  'Chat Now',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}