import 'dart:io';

import 'package:blood_donation/Models/organization_model.dart';
import 'package:blood_donation/Provider/organization_provider.dart';
import 'package:blood_donation/Provider/organization_storage_provider.dart';
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateForm(BuildContext context) {
    if (selectedImage == null) {
      _showError(context, 'Please select organization image');
      return false;
    }
    if (nameCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter organization name');
      return false;
    }
    if (countryCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter country');
      return false;
    }
    if (cityCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter city');
      return false;
    }
    if (addressCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter address');
      return false;
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter phone number');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Organization')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// IMAGE PICKER
            InkWell(
              onTap: () async {
                final file = await pickImage();
                if (file == null) return;

                setState(() {
                  selectedImage = file;
                });
              },
              child: CircleAvatar(
                radius: 40.h,
                backgroundImage: selectedImage != null
                    ? FileImage(selectedImage!)
                    : null,
                child: selectedImage == null
                    ? const Icon(Icons.camera_alt)
                    : null,
              ),
            ),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: countryCtrl,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            TextField(
              controller: cityCtrl,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),

            const SizedBox(height: 20),

            /// SAVE BUTTON
            Consumer2<OrganizationProvider, OrganizationStorageProvider>(
              builder: (context, orgProvider, storageProvider, _) {
                return ElevatedButton(
                  onPressed: orgProvider.isLoading || storageProvider.isLoading
                      ? null
                      : () async {
                          if (!_validateForm(context)) return;
                          final docRef = FirebaseFirestore.instance
                              .collection('organizations')
                              .doc();

                          final org = OrganizationModel(
                            id: docRef.id,
                            name: nameCtrl.text.trim(),
                            country: countryCtrl.text.trim(),
                            city: cityCtrl.text.trim(),
                            address: addressCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            image: '',
                          );

                          // Create organization
                          await orgProvider.addOraganization(org);

                          //  Upload image (if selected)
                          if (selectedImage != null) {
                            await storageProvider.uploadImage(
                              org.id,
                              selectedImage!,
                            );
                          }

                          Navigator.pop(context);
                        },
                  child: (orgProvider.isLoading || storageProvider.isLoading)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Organization'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
