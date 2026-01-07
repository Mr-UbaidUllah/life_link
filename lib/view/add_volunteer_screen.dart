import 'dart:io';

import 'package:blood_donation/Models/ambulance_model.dart';
import 'package:blood_donation/Models/volunteer_model.dart';
import 'package:blood_donation/Provider/ambulance_provider.dart';
import 'package:blood_donation/Provider/ambulance_storage_provider.dart';
import 'package:blood_donation/Provider/volunteer_provider.dart';
import 'package:blood_donation/Provider/volunteer_storagar_provider.dart';
import 'package:blood_donation/core/services/voluntter_storage_service.dart';
import 'package:blood_donation/widgets/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AddVolunteerScreen extends StatefulWidget {
  const AddVolunteerScreen({super.key});

  @override
  State<AddVolunteerScreen> createState() => _AddOrganizationScreenState();
}

class _AddOrganizationScreenState extends State<AddVolunteerScreen> {
  final volunteerName = TextEditingController();
  final VolunteerWork = TextEditingController();
  // final cityCtrl = TextEditingController();
  // final addressCtrl = TextEditingController();
  // final phoneCtrl = TextEditingController();

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
    if (volunteerName.text.trim().isEmpty) {
      _showError(context, 'Please enter Ambulance name');
      return false;
    }
    // if (countryCtrl.text.trim().isEmpty) {
    //   _showError(context, 'Please enter country');
    //   return false;
    // }
    if (VolunteerWork.text.trim().isEmpty) {
      _showError(context, 'Please enter city');
      return false;
    }
    // if (addressCtrl.text.trim().isEmpty) {
    //   _showError(context, 'Please enter address');
    //   return false;
    // }
    // if (phoneCtrl.text.trim().isEmpty) {
    //   _showError(context, 'Please enter phone number');
    //   return false;
    // }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Volunteer')),
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
              controller: volunteerName,
              decoration: const InputDecoration(labelText: 'Volunteer  Name'),
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
              controller: VolunteerWork,
              decoration: const InputDecoration(labelText: 'Work descriptionm'),
            ),

            // TextField(
            //   controller: addressCtrl,
            //   decoration: const InputDecoration(labelText: 'Address'),
            // ),
            // TextField(
            //   controller: phoneCtrl,
            //   decoration: const InputDecoration(labelText: 'Phone'),
            // ),
            const SizedBox(height: 20),

            /// SAVE BUTTON
            Consumer2<VolunteerProvider, volunteerStorageProvider>(
              builder:
                  (
                    BuildContext context,
                    VolunteerProvider volunteer,
                    storage,
                    Widget? child,
                  ) {
                    return ElevatedButton(
                      onPressed: () async {
                        if (!_validateForm(context)) return;
                        final docRef = FirebaseFirestore.instance
                            .collection('Volunteer')
                            .doc();
                        final vol = VolunteerModel(
                          id: docRef.id,
                          name: volunteerName.text,
                          imageUrl: '',
                          workDescription: VolunteerWork.text,
                        );
                        await volunteer.addVolunteer(vol);
                        // final org = AmbulanceModel(
                        //   id: docRef.id,
                        //   ambulanceName: volunteerName.text,
                        //   hospitalName: VolunteerWork.text,
                        //   // address: addressCtrl.text,
                        //   imageUrl: '',
                        //   // phoneNumber: phoneCtrl.text,
                        // );

                        // Create organization
                        // await ambulance.addAmbulance(org);

                        //  Upload image (if selected)
                        if (selectedImage != null) {
                          await storage.uploadImage(vol.id, selectedImage!);
                        }
 
                        Navigator.pop(context);
                      },
                      child: const Text('Save Volunteer'),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
