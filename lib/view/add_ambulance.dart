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

class AddAmbulance extends StatefulWidget {
  const AddAmbulance({super.key});

  @override
  State<AddAmbulance> createState() => _AddAmbulanceState();
}

class _AddAmbulanceState extends State<AddAmbulance> {
  final nameCtrl = TextEditingController();
  final hospitalCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  
  AmbulanceType selectedType = AmbulanceType.basic;
  File? selectedImage;

  @override
  void dispose() {
    nameCtrl.dispose();
    hospitalCtrl.dispose();
    addressCtrl.dispose();
    phoneCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }

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
    if (priceCtrl.text.trim().isEmpty) {
      _showError(context, theme, 'Please enter base price');
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
          'Register Ambulance',
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
                      radius: 55.r,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                      child: selectedImage == null
                          ? Icon(Icons.airport_shuttle_rounded, size: 45.r, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
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
            
            SizedBox(height: 30.h),

            CustomTextField(
              controller: hospitalCtrl,
              labelText: 'Hospital Name',
              hintText: 'Associated hospital name',
              prefixIcon: Icons.local_hospital_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: nameCtrl,
              labelText: 'Ambulance Name/Model',
              hintText: 'e.g. Life Care - Van A1',
              prefixIcon: Icons.bus_alert_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),

            Text(
              'Select Ambulance Type',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              children: AmbulanceType.values.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(type.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => selectedType = type);
                  },
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: priceCtrl,
                    labelText: 'Base Price',
                    hintText: '0.00',
                    prefixIcon: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                    borderRadius: 16.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: CustomTextField(
                    controller: phoneCtrl,
                    labelText: 'Contact Number',
                    hintText: 'Emergency phone',
                    prefixIcon: Icons.phone_in_talk_rounded,
                    keyboardType: TextInputType.phone,
                    borderRadius: 16.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            
            CustomTextField(
              controller: addressCtrl,
              labelText: 'Station Address',
              hintText: 'Enter pickup/station address',
              prefixIcon: Icons.location_on_rounded,
              borderRadius: 16.r,
            ),

            SizedBox(height: 40.h),

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
                              type: selectedType,
                              basePrice: priceCtrl.text.trim(),
                            );

                            try {
                              await ambulanceProv.addAmbulance(model);

                              // uploadImage returns false on failure; don't
                              // claim full success if the image didn't upload.
                              bool imageOk = true;
                              if (selectedImage != null) {
                                imageOk = await storageProv.uploadImage(model.id, selectedImage!);
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(imageOk
                                      ? 'Ambulance service added successfully'
                                      : 'Ambulance added, but the image upload failed.'),
                                  backgroundColor: imageOk ? Colors.green : Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              _showError(
                                context,
                                theme,
                                'Could not add ambulance. Check your connection and try again.',
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
                            'Register Ambulance',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
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
