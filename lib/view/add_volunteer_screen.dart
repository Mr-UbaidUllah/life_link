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
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final skillsController = TextEditingController();
  final bioController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();

  String? selectedRole;
  File? selectedImage;

  final List<String> roles = [
    'Blood Donor Coordinator',
    'Medical Professional',
    'First Aid Responder',
    'Event Organizer',
    'Social Media Manager',
    'Logistics Assistant',
    'Community Advocate',
    'Other',
  ];

  @override
  void dispose() {
    nameController.dispose();
    skillsController.dispose();
    bioController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Join Community',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Become a Volunteer',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'Fill in your details to help us grow our network.',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: 30.h),

              /// IMAGE PICKER
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: selectedImage != null ? FileImage(selectedImage!) : null,
                        child: selectedImage == null
                            ? Icon(Icons.person_add_alt_1_rounded, size: 40.r, color: theme.colorScheme.primary.withValues(alpha: 0.5))
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () async {
                          final file = await pickImage();
                          if (file != null) setState(() => selectedImage = file);
                        },
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40.h),

              _buildSectionTitle('Basic Information', theme),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: nameController,
                labelText: 'Full Name',
                hintText: 'How should we call you?',
                prefixIcon: Icons.person_outline_rounded,
                borderRadius: 12.r,
              ),
              SizedBox(height: 16.h),
              
              // ROLE DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Current Role',
                  prefixIcon: Icon(Icons.badge_outlined, size: 20.sp, color: theme.colorScheme.primary),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                hint: const Text('Select your volunteer role'),
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value;
                  });
                },
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              
              SizedBox(height: 16.h),
              CustomTextField(
                controller: phoneController,
                labelText: 'Phone Number',
                hintText: '+1 234 567 890',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                borderRadius: 12.r,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: locationController,
                labelText: 'Location',
                hintText: 'City, Country',
                prefixIcon: Icons.location_on_outlined,
                borderRadius: 12.r,
              ),

              SizedBox(height: 32.h),
              _buildSectionTitle('Expertise & Bio', theme),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: skillsController,
                labelText: 'Skills / Expertise',
                hintText: 'e.g. First Aid, Event Management',
                prefixIcon: Icons.bolt_rounded,
                borderRadius: 12.r,
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                controller: bioController,
                labelText: 'Short Bio',
                hintText: 'Tell us a bit about your passion for volunteering...',
                prefixIcon: Icons.info_outline_rounded,
                borderRadius: 12.r,
                maxLines: 4,
                height: 120.h,
              ),

              SizedBox(height: 40.h),

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
                              if (selectedImage == null) {
                                _showError('Please select a profile image');
                                return;
                              }
                              if (nameController.text.isEmpty || selectedRole == null) {
                                _showError('Name and Role are required');
                                return;
                              }

                              final docRef = FirebaseFirestore.instance.collection('Volunteer').doc();
                              
                              final vol = VolunteerModel(
                                id: docRef.id,
                                name: nameController.text.trim(),
                                imageUrl: '',
                                workDescription: selectedRole!,
                                skills: skillsController.text.trim(),
                                bio: bioController.text.trim(),
                                phone: phoneController.text.trim(),
                                location: locationController.text.trim(),
                              );
                              
                              try {
                                await volunteerProv.addVolunteer(vol);

                                bool imageOk = true;
                                if (selectedImage != null) {
                                  imageOk = await storageProv.uploadImage(vol.id, selectedImage!);
                                }

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(imageOk
                                        ? 'Welcome to the community! ❤️'
                                        : 'Registered, but the image upload failed.'),
                                    backgroundColor: imageOk ? Colors.green : Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                _showError('Could not submit. Check your connection and try again.');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: isLoading
                          ? SizedBox(height: 20.r, width: 20.r, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Submit Application', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}
