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
  final descriptionCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  
  OrganizationType selectedType = OrganizationType.ngo;
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
    if (phoneCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter phone number');
      return false;
    }
    if (addressCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter address');
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
          'Register Partner',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE PICKER
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 60.r,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                      child: selectedImage == null
                          ? Icon(Icons.business_rounded, size: 50.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
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
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30.h),
            
            Text('Basic Information', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            SizedBox(height: 16.h),

            CustomTextField(
              controller: nameCtrl,
              labelText: 'Organization Name',
              hintText: 'e.g. City General Hospital',
              prefixIcon: Icons.business_outlined,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),

            DropdownButtonFormField<OrganizationType>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Organization Type',
                prefixIcon: Icon(Icons.category_outlined, color: theme.colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              items: OrganizationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedType = value);
              },
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              controller: descriptionCtrl,
              labelText: 'About / Description',
              hintText: 'Tell us about your organization...',
              prefixIcon: Icons.description_outlined,
              borderRadius: 16.r,
              maxLines: 3,
            ),
            
            SizedBox(height: 24.h),
            Text('Location Details', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: countryCtrl,
                    labelText: 'Country',
                    hintText: 'Country',
                    prefixIcon: Icons.public_rounded,
                    borderRadius: 16.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: CustomTextField(
                    controller: cityCtrl,
                    labelText: 'City',
                    hintText: 'City',
                    prefixIcon: Icons.location_city_rounded,
                    borderRadius: 16.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: addressCtrl,
              labelText: 'Full Address',
              hintText: 'Street address, building number...',
              prefixIcon: Icons.location_on_outlined,
              borderRadius: 16.r,
            ),
            
            SizedBox(height: 24.h),
            Text('Contact & Links', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: phoneCtrl,
              labelText: 'Phone Number',
              hintText: '+1 234 567 890',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              controller: emailCtrl,
              labelText: 'Email Address',
              hintText: 'contact@org.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),

            CustomTextField(
              controller: websiteCtrl,
              labelText: 'Website (Optional)',
              hintText: 'www.organization.com',
              prefixIcon: Icons.language_rounded,
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
                              description: descriptionCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              website: websiteCtrl.text.trim(),
                              type: selectedType,
                              image: '',
                              joinedAt: DateTime.now(),
                              isVerified: false,
                              rating: 4.5, // Default for demo purposes
                            );

                            try {
                              await orgProvider.addOraganization(org);

                              bool imageOk = true;
                              if (selectedImage != null) {
                                imageOk = await storageProvider.uploadImage(org.id, selectedImage!);
                              }

                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(imageOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: Colors.white),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(imageOk
                                            ? 'Partner registered successfully!'
                                            : 'Partner registered, but the image upload failed.'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: imageOk ? Colors.green : Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              _showError(
                                context,
                                theme,
                                'Could not register partner. Check your connection and try again.',
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
                        ? SizedBox(
                            height: 24.r,
                            width: 24.r,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Register Organization',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              },
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }
}
