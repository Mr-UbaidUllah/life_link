import 'package:blood_donation/view/HomeScreens/home_screen.dart';
import 'package:blood_donation/view/post_details.dart';
import 'package:blood_donation/widgets/contactsContainer.dart';
import 'package:blood_donation/widgets/dropdownheader.dart';
import 'package:blood_donation/widgets/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BloodrequestScreen extends StatefulWidget {
  const BloodrequestScreen({super.key});

  @override
  State<BloodrequestScreen> createState() => _BloodrequestScreenState();
}

class _BloodrequestScreenState extends State<BloodrequestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Blood Request'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            child: Dropdownheader(name: 'Blood Request'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailsScreen(),
                      ),
                    );
                  },
                  child: homeContainer(bloodGroups: ['A', 'B', 'c']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
