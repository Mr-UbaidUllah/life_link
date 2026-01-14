import 'dart:io';

import 'package:blood_donation/models/ambulance_model.dart';
import 'package:blood_donation/provider/ambulance_provider.dart';
import 'package:blood_donation/provider/ambulance_storage_provider.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddAmbulence extends StatefulWidget {
  const AddAmbulence({super.key});

  @override
  State<AddAmbulence> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddAmbulence> {
  final ambulancenameCtrl = TextEditingController();
  final hospitolname = TextEditingController();
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
      _showError(context, 'Please select Ambulance image');
      return false;
    }
    if (ambulancenameCtrl.text.trim().isEmpty) {
      _showError(context, 'Please enter Ambulance name');
      return false;
    }
    // if (countryCtrl.text.trim().isEmpty) {
    //   _showError(context, 'Please enter country');
    //   return false;
    // }
    if (hospitolname.text.trim().isEmpty) {
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
      appBar: AppBar(title: const Text('Add Ambulence')),
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
              controller: ambulancenameCtrl,
              decoration: const InputDecoration(labelText: 'Ambulance Name'),
            ),
            // TextField(
            //   controller: countryCtrl,
            //   decoration: const InputDecoration(labelText: 'Country'),
            // ),
            // TextField(
            //   controller: cityCtrl,
            //   decoration: const InputDecoration(labelText: 'City'),
            // ),
            TextField(
              controller: hospitolname,
              decoration: const InputDecoration(labelText: 'Hospitol name'),
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
            Consumer2<AmbulanceProvider,AmbulanceStorageProvider>(

              builder: (context, ambulance,storage, _) {
                return ElevatedButton(
                  onPressed: ambulance.isLoading
                      ? null
                      : () async {
                          if (!_validateForm(context)) return;
                          final docRef = FirebaseFirestore.instance
                              .collection('Ambulance')
                              .doc();

                          final org = AmbulanceModel(
                            id: docRef.id,
                            ambulanceName: ambulancenameCtrl.text,
                            hospitalName: hospitolname.text,
                            address: addressCtrl.text,
                            imageUrl: '',
                            phoneNumber: phoneCtrl.text,
                          );

                          // Create organization
                          await ambulance.addAmbulance(org);

                          //  Upload image (if selected)
                          if (selectedImage != null) {
                            await storage.uploadImage(org.id, selectedImage!);
                          }

                          Navigator.pop(context);
                        },
                  child: (ambulance.isLoading)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Ambulance'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
