import 'dart:io';
import 'package:blood_donation/models/volunteer_model.dart';
import 'package:blood_donation/provider/volunteer_provider.dart';
import 'package:blood_donation/provider/volunteer_storagar_provider.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddVolunteerScreen extends StatefulWidget {
  const AddVolunteerScreen({super.key});

  @override
  State<AddVolunteerScreen> createState() => _AddVolunteerScreenState();
}

class _AddVolunteerScreenState extends State<AddVolunteerScreen> {
  final volunteerName = TextEditingController();
  final volunteerWork = TextEditingController();

  File? selectedImage;

  void _showError(BuildContext context, ThemeData theme, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  bool _validateForm(BuildContext context, ThemeData theme) {
    if (selectedImage == null) {
      _showError(context, theme, 'Please select volunteer image');
      return false;
    }
    if (volunteerName.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter volunteer name');
      return false;
    }
    if (volunteerWork.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter work description');
      return false;
    }
    return true;
  }

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
          'Add Volunteer',
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// IMAGE PICKER
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 55.r,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                      child: selectedImage == null
                          ? Icon(Icons.person_add_alt_1_rounded, size: 45.r, color: theme.colorScheme.onSurface.withOpacity(0.4))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () async {
                        final file = await pickImage();
                        if (file == null) return;
                        setState(() {
                          selectedImage = file;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40.h),

            CustomTextField(
              controller: volunteerName,
              labelText: 'Volunteer Name',
              hintText: 'Enter volunteer full name',
              prefixIcon: Icons.person_outline_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 20.h),
            
            CustomTextField(
              controller: volunteerWork,
              labelText: 'Work Description',
              hintText: 'e.g. Blood Donor Coordinator',
              prefixIcon: Icons.work_outline_rounded,
              borderRadius: 16.r,
              maxLines: 3,
              height: 120.h,
            ),

            SizedBox(height: 50.h),

            /// SAVE BUTTON
            Consumer2<VolunteerProvider, volunteerStorageProvider>(
              builder: (context, volunteerProv, storageProv, _) {
                final bool isLoading = volunteerProv.isLoading || storageProv.isLoading;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_validateForm(context, theme)) return;
                            final docRef = FirebaseFirestore.instance.collection('Volunteer').doc();
                            
                            final vol = VolunteerModel(
                              id: docRef.id,
                              name: volunteerName.text.trim(),
                              imageUrl: '',
                              workDescription: volunteerWork.text.trim(),
                            );
                            
                            await volunteerProv.addVolunteer(vol);

                            if (selectedImage != null) {
                              await storageProv.uploadImage(vol.id, selectedImage!);
                            }
 
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Volunteer added successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save Volunteer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
