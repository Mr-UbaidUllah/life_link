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
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickFile != null) {
      final File imageFile = File(pickFile.path);
      final int imageSize = await imageFile.length();
      
      if (imageSize <= 1048576) {
        setState(() {
          selectedImage = imageFile;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image size must be less than or equal to 1 MB"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Setup',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt_outlined, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Step 3 of 3',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Add a photo so your community can recognize you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: pickImage,
                    child: DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: theme.colorScheme.primary.withOpacity(0.5),
                        strokeWidth: 2,
                        dashPattern: const [8, 4],
                        radius: const Radius.circular(20),
                      ),
                      child: Container(
                        height: 250.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          image: selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImage == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 64.sp,
                                    color: theme.colorScheme.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Tap to upload photo",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Maximum size 1MB",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    right: 12,
                                    top: 12,
                                    child: CircleAvatar(
                                      backgroundColor: theme.colorScheme.primary,
                                      radius: 18,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.edit,
                                            size: 18, color: Colors.white),
                                        onPressed: pickImage,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  InkWell(
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
                    child: const ReusableButton(label: 'Complete Setup'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Skip for now',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w500),
                    ),
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
