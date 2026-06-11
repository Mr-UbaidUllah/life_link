import 'dart:io';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ImageScreen extends StatefulWidget {
  const ImageScreen({super.key});

  @override
  State<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  File? selectedImage;
  bool _isCompleting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _completeSetup() async {
    if (_isCompleting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final storageProvider = context.read<StorageProvider>();

    setState(() => _isCompleting = true);
    try {
      // Upload the chosen profile photo first (if any). uploadImage also
      // writes the download URL to users/{uid}.profileImage.
      if (selectedImage != null) {
        final uploaded =
            await storageProvider.uploadImage(user.uid, selectedImage!);
        if (!uploaded) {
          throw Exception(
              storageProvider.error ?? 'Could not upload your photo. Please try again.');
        }
      }

      // set+merge (not update) so a missing/partial profile doc still completes.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'profileCompleted': true}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException &&
        (e.code == 'unavailable' || e.code == 'network-request-failed')) {
      return 'No internet connection. Check your network and try again.';
    }
    // Upload failures are rethrown as Exception(<friendly reason>); show that.
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Could not finish setup. Please try again.';
  }

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
          onPressed: () => Navigator.maybePop(context),
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
                  SizedBox(height: 12.h),
                  Text(
                    'Step 3 of 3',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 20.sp,
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
                    style: TextStyle(fontSize: 16.sp, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  SizedBox(height: 40.h),
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
                                  SizedBox(height: 12.h),
                                  Text(
                                    "Tap to upload photo",
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Maximum size 1MB",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                                      fontSize: 12.sp,
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
                  SizedBox(height: 60.h),
                  InkWell(
                    onTap: _isCompleting ? null : _completeSetup,
                    child: _isCompleting
                        ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                        : const ReusableButton(label: 'Complete Setup'),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: _isCompleting ? null : _completeSetup,
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
