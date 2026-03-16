import 'dart:io';
import 'package:blood_donation/models/organization_model.dart';
import 'package:blood_donation/provider/organization_provider.dart';
import 'package:blood_donation/provider/organization_storage_provider.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddOrganizationScreen extends StatefulWidget {
  const AddOrganizationScreen({super.key});

  @override
  State<AddOrganizationScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddOrganizationScreen> {
  final nameCtrl = TextEditingController();
  final countryCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

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
      _showError(context, theme, 'Please select organization image');
      return false;
    }
    if (nameCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter organization name');
      return false;
    }
    if (countryCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter country');
      return false;
    }
    if (cityCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter city');
      return false;
    }
    if (addressCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter address');
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter phone number');
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
          'Add Organization',
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
                      radius: 50.r,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                      child: selectedImage == null
                          ? Icon(Icons.business_rounded, size: 40.r, color: theme.colorScheme.onSurface.withOpacity(0.4))
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
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
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30.h),

            CustomTextField(
              controller: nameCtrl,
              labelText: 'Organization Name',
              hintText: 'Enter organization name',
              prefixIcon: Icons.business_outlined,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: countryCtrl,
              labelText: 'Country',
              hintText: 'Enter country',
              prefixIcon: Icons.public_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: cityCtrl,
              labelText: 'City',
              hintText: 'Enter city',
              prefixIcon: Icons.location_city_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: addressCtrl,
              labelText: 'Full Address',
              hintText: 'Enter complete address',
              prefixIcon: Icons.location_on_outlined,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: phoneCtrl,
              labelText: 'Phone Number',
              hintText: 'Enter contact number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              borderRadius: 16.r,
            ),

            SizedBox(height: 40.h),

            /// SAVE BUTTON
            Consumer2<OrganizationProvider, OrganizationStorageProvider>(
              builder: (context, orgProvider, storageProvider, _) {
                final bool isLoading = orgProvider.isLoading || storageProvider.isLoading;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_validateForm(context, theme)) return;
                            final docRef = FirebaseFirestore.instance.collection('organizations').doc();

                            final org = OrganizationModel(
                              id: docRef.id,
                              name: nameCtrl.text.trim(),
                              country: countryCtrl.text.trim(),
                              city: cityCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              image: '',
                            );

                            await orgProvider.addOraganization(org);

                            if (selectedImage != null) {
                              await storageProvider.uploadImage(org.id, selectedImage!);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Organization added successfully'),
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
                            'Save Organization',
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
