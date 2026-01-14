import 'dart:io';

import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  File? SelectedImage;
  final ImagePicker _picker = ImagePicker();
  Future<void> PickImage() async {
    final XFile? Pickfile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (Pickfile != null) {
      final File imageFile = File(Pickfile.path);
      //  Get file size in bytes
      final int imageSize = await imageFile.length();
      //  1 MB = 1048576 bytes
      if (imageSize <= 1048576) {
        setState(() {
          SelectedImage = File(Pickfile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image size must be less than or equal to 1 MB"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 60.h),

          Divider(color: Colors.grey, thickness: 0.5),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h),
            child: Text(
              'Profile Setup',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20.h,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.h),
            child: Text(
              'Almost Done to set your profile,fill up below\ninformation, its easy just 3 steps',
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ),
          SizedBox(height: 20.h),

          Divider(color: Colors.grey, thickness: 0.5.h),
          SizedBox(height: 20.h),

          GestureDetector(
            onTap: () {
              PickImage();
            },
            child: Container(
              height: 100.h,
              // width: width * 0.20,v
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
                image: SelectedImage != null
                    ? DecorationImage(
                        image: FileImage(SelectedImage!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: SelectedImage == null
                  ? Center(
                      child: Icon(
                        Icons.person_3_outlined,
                        size: 30.h,
                        color: Colors.red,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Upload your image',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          DottedBorder(
            options: RoundedRectDottedBorderOptions(
              radius: Radius.circular(20),
            ),

            child: InkWell(
              onTap: () {
                PickImage();
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: SelectedImage != null
                      ? DecorationImage(
                          image: FileImage(SelectedImage!),
                          fit: BoxFit.contain,
                        )
                      : null,
                ),
                height: 200.h,
                width: 350.w,
                alignment: Alignment.center,
                child: SelectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Upload your profile photo",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.h),
              child: Text(
                'uplaod Upto to 1mb',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: 40.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.h),
            child: InkWell(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({'profileCompleted': true});

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                }
              },
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()),
                  );
                },
                child: ReusableButton(label: 'Home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
