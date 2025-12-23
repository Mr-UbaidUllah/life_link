import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back_ios_new),
        title: Text(
          'Post Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Blood Icon
            Center(
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.red.withOpacity(0.1),
                child: Icon(Icons.bloodtype, color: Colors.red, size: 40),
              ),
            ),

            const SizedBox(height: 12),

            /// Title
            Center(
              child: Text(
                'Emergency B+ Blood Needed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            /// Info Card
            Container(
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6.sp)],
              ),
              child: Column(
                children: [
                  infoRow(Icons.person, 'Contact Person', 'Person Name'),
                  infoRow(Icons.call, 'Mobile Number', '+88 011122233344'),
                  infoRow(Icons.bloodtype, 'How many Bag(s)', '3 Bags'),
                  infoRow(Icons.public, 'Country', 'Bangladesh'),
                  infoRow(Icons.location_city, 'City', 'Dhaka'),
                  infoRow(Icons.local_hospital, 'Hospital', 'Nur Hospital'),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            /// Description
            Text(
              'Why do you need blood?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),

            const SizedBox(height: 8),

            Text(
              'sunt in culpa qui officia deserunt mollitia animi, '
              'id est laborum et dolorum fuga. Et harum quidem rerum '
              'facilis expedita',
              style: TextStyle(color: Colors.grey[700]),
            ),

            const SizedBox(height: 20),

            /// Message Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'If you interest to donate blood please contact with '
                'Person Name. View Profile',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),

            /// Tags
            Wrap(
              spacing: 8,
              children: [
                tagChip('#Baby'),
                tagChip('#Oldman'),
                tagChip('#Urgents'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable Info Row
  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Reusable Tag Chip
  Widget tagChip(String label) {
    return Chip(
      label: Text(label, style: TextStyle(color: Colors.red)),
      backgroundColor: Colors.red.withOpacity(0.1),
      shape: StadiumBorder(),
    );
  }
}
