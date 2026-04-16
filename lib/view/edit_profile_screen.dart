import 'dart:io';
import 'package:blood_donation/models/user_model.dart';
import 'package:blood_donation/provider/storage_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _aboutController;
  late final TextEditingController _dobController;
  
  String? _selectedBloodGroup;
  String? _selectedGender;
  bool _isDonor = false;
  File? _image;
  bool _isLoading = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _cityController = TextEditingController(text: widget.user.city);
    _countryController = TextEditingController(text: widget.user.country);
    _aboutController = TextEditingController(text: widget.user.about);
    _dobController = TextEditingController(text: widget.user.dateOfBirth);
    _selectedBloodGroup = widget.user.bloodGroup;
    _selectedGender = widget.user.gender;
    _isDonor = widget.user.isDonor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _aboutController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      } catch (e) {
        // use default
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final storageProvider = Provider.of<StorageProvider>(context, listen: false);

    try {
      if (_image != null) {
        final uploaded = await storageProvider.uploadImage(widget.user.uid, _image!);
        if (!uploaded) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Update basic info if it changed
      if (_isDonor != widget.user.isDonor) {
        await userProvider.toggleDonate(_isDonor);
      }

      final success = await userProvider.updatePersonalInfo(
        uid: widget.user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        bloodGroup: _selectedBloodGroup ?? '',
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        dateOfBirth: _dobController.text,
        gender: _selectedGender,
        about: _aboutController.text.trim(),
      );

      if (success) {
        await userProvider.loadCurrentUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(userProvider.error ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          'Edit Profile',
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
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// PROFILE IMAGE PICKER
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60.r,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (widget.user.profileImage != null && widget.user.profileImage!.isNotEmpty
                                ? NetworkImage(widget.user.profileImage!)
                                : null) as ImageProvider?,
                        child: _image == null && (widget.user.profileImage == null || widget.user.profileImage!.isEmpty)
                            ? Icon(Icons.person_rounded, size: 60.r, color: theme.colorScheme.onSurface.withOpacity(0.4))
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt_rounded, size: 20.sp, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40.h),

              _buildSectionTitle('Personal Details', theme),
              SizedBox(height: 16.h),
              
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                hintText: 'Enter your name',
                prefixIcon: Icons.person_outline_rounded,
                focusedBorderColor: theme.colorScheme.primary,
                borderRadius: 16.r,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: CustomDropdownFormField<String>(
                      value: _selectedGender,
                      items: _genders,
                      itemToString: (value) => value,
                      labelText: 'Gender',
                      hintText: 'Select',
                      onChanged: (val) => setState(() => _selectedGender = val),
                      prefixIcon: Icon(Icons.wc_rounded, color: theme.colorScheme.primary, size: 22.sp),
                      borderRadius: 16.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: CustomTextField(
                          controller: _dobController,
                          labelText: 'Date of Birth',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icons.calendar_today_rounded,
                          borderRadius: 16.r,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                hintText: 'Enter your phone number',
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                focusedBorderColor: theme.colorScheme.primary,
                borderRadius: 16.r,
              ),

              SizedBox(height: 30.h),
              _buildSectionTitle('Medical Information', theme),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: CustomDropdownFormField<String>(
                      value: _selectedBloodGroup,
                      items: _bloodGroups,
                      itemToString: (value) => value,
                      labelText: 'Blood Group',
                      hintText: 'Select',
                      onChanged: (val) => setState(() => _selectedBloodGroup = val),
                      prefixIcon: Icon(Icons.bloodtype_rounded, color: Colors.redAccent, size: 22.sp),
                      borderRadius: 16.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available to Donate',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 56.h,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_isDonor ? 'Yes' : 'No', style: TextStyle(fontSize: 15.sp)),
                              Switch.adaptive(
                                value: _isDonor,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (val) => setState(() => _isDonor = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30.h),
              _buildSectionTitle('Location & Bio', theme),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _countryController,
                      labelText: 'Country',
                      hintText: 'Country',
                      prefixIcon: Icons.public_rounded,
                      borderRadius: 16.r,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      labelText: 'City',
                      hintText: 'City',
                      prefixIcon: Icons.location_city_rounded,
                      borderRadius: 16.r,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              CustomTextField(
                controller: _aboutController,
                labelText: 'About Me',
                hintText: 'Write a short bio...',
                prefixIcon: Icons.info_outline_rounded,
                maxLines: 4,
                borderRadius: 16.r,
              ),

              SizedBox(height: 40.h),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24.h,
                          width: 24.h,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
