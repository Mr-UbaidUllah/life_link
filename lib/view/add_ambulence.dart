import 'dart:io';
import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/provider/ambulance_storage_provider.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddAmbulence extends StatefulWidget {
  const AddAmbulence({super.key});

  @override
  State<AddAmbulence> createState() => _AddAmbulenceState();
}

class _AddAmbulenceState extends State<AddAmbulence> {
  final nameCtrl = TextEditingController();
  final hospitalCtrl = TextEditingController();
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
      _showError(context, theme, 'Please select ambulance image');
      return false;
    }
    if (nameCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter ambulance name');
      return false;
    }
    if (hospitalCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter hospital name');
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
          'Add Ambulance',
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
                          ? Icon(Icons.airport_shuttle_rounded, size: 45.r, color: theme.colorScheme.onSurface.withOpacity(0.4))
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
              controller: nameCtrl,
              labelText: 'Ambulance Name',
              hintText: 'e.g. Life Care Ambulance',
              prefixIcon: Icons.bus_alert_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: hospitalCtrl,
              labelText: 'Hospital Name',
              hintText: 'Associated hospital name',
              prefixIcon: Icons.local_hospital_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: addressCtrl,
              labelText: 'Full Address',
              hintText: 'Enter pickup/station address',
              prefixIcon: Icons.location_on_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: phoneCtrl,
              labelText: 'Contact Number',
              hintText: 'Enter emergency number',
              prefixIcon: Icons.phone_in_talk_rounded,
              keyboardType: TextInputType.phone,
              borderRadius: 16.r,
            ),

            SizedBox(height: 50.h),

            /// SAVE BUTTON
            Consumer2<AmbulanceProvider, AmbulanceStorageProvider>(
              builder: (context, ambulanceProv, storageProv, _) {
                final bool isLoading = ambulanceProv.isLoading || storageProv.isLoading;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!_validateForm(context, theme)) return;
                            final docRef = FirebaseFirestore.instance.collection('Ambulance').doc();

                            final model = AmbulanceModel(
                              id: docRef.id,
                              ambulanceName: nameCtrl.text.trim(),
                              hospitalName: hospitalCtrl.text.trim(),
                              address: addressCtrl.text.trim(),
                              imageUrl: '',
                              phoneNumber: phoneCtrl.text.trim(),
                            );

                            await ambulanceProv.addAmbulance(model);

                            if (selectedImage != null) {
                              await storageProv.uploadImage(model.id, selectedImage!);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ambulance service added successfully'),
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
                            'Save Ambulance',
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
