import 'package:blood_donation/Models/bloodrequest_model.dart';
import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/profile/profile_details_scrren.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PostDetailsScreen extends StatefulWidget {
  final BloodRequestModel request;

  const PostDetailsScreen({super.key, required this.request});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<UserProvider>().loadUserById(widget.request.userId);
    });
  }

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
      body: Consumer<UserProvider>(
        builder: (BuildContext context, UserProvider provider, Widget? child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = provider.postUser;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          final request = widget.request;
          return SingleChildScrollView(
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
                    request.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 24),

                /// Info Card
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfileDetailsScreen(userId: request.userId),
                      ),
                    );
                  },

                  child: Container(
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 6.sp),
                      ],
                    ),
                    child: Column(
                      children: [
                        infoRow(
                          Icons.person,
                          'Contact Person',
                          request.contactName,
                        ),
                        infoRow(Icons.call, 'Mobile Number', request.phone),
                        infoRow(
                          Icons.bloodtype,
                          'How many Bag(s)',
                          request.bags.toString(),
                        ),
                        infoRow(Icons.public, 'Country', request.country),
                        infoRow(Icons.location_city, 'City', request.city),
                        infoRow(
                          Icons.local_hospital,
                          'Hospital',
                          request.hospital,
                        ),
                      ],
                    ),
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
          );
        },
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
