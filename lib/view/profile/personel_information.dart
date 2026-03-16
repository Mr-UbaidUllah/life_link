import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/profile/basic_information.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PersonelInformation extends StatefulWidget {
  const PersonelInformation({super.key});

  @override
  State<PersonelInformation> createState() => _PersonelInformationState();
}

class _PersonelInformationState extends State<PersonelInformation> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String? selectedBloodGroup;
  String? selectedCountry;
  String? selectedCity;

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> countries = ['Pakistan', 'India', 'USA', 'UAE', 'Canada'];
  final List<String> citiesPakistan = [
    'Peshawar',
    'Lahore',
    'Karachi',
    'Islamabad',
  ];
  final List<String> citiesIndia = ['Delhi', 'Mumbai', 'Bangalore'];
  final List<String> citiesUSA = ['New York', 'Los Angeles', 'Chicago'];

  List<String> getCityList() {
    if (selectedCountry == 'Pakistan') {
      return citiesPakistan;
    }
    if (selectedCountry == 'India') {
      return citiesIndia;
    }
    if (selectedCountry == 'USA') {
      return citiesUSA;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Consumer<AuthProviders>(
          builder: (context, auth, _) {
            return IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
            );
          },
        ),
        title: Text(
          'Profile Setup',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 30.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32.r),
                  bottomRight: Radius.circular(32.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
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
                          child: Icon(Icons.person_rounded, size: 50.r, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.surface, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded, size: 18.sp, color: theme.colorScheme.onPrimary),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Step 1 of 3',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Tell us a bit about yourself',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Details', theme),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: nameController,
                    hintText: "Full Name",
                    prefixIcon: Icons.person_outline_rounded,
                    borderRadius: 16.r,
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    controller: phoneController,
                    hintText: "Mobile Number",
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_android_rounded,
                    borderRadius: 16.r,
                  ),
                  SizedBox(height: 32.h),
                  _buildSectionTitle('Location & Health', theme),
                  SizedBox(height: 16.h),
                  CustomDropdownFormField(
                    hintText: 'Select Blood Group',
                    value: selectedBloodGroup,
                    items: bloodGroups,
                    itemToString: (item) => item,
                    borderRadius: 16.r,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.bloodtype_rounded, color: theme.colorScheme.primary.withOpacity(0.6), size: 22.sp),
                    onChanged: (value) {
                      setState(() {
                        selectedBloodGroup = value;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  CustomDropdownFormField(
                    hintText: 'Select Country',
                    value: selectedCountry,
                    items: countries,
                    itemToString: (item) => item,
                    borderRadius: 16.r,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.public_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22.sp),
                    onChanged: (val) {
                      setState(() {
                        selectedCountry = val;
                        selectedCity = null;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  CustomDropdownFormField(
                    hintText: 'Select City',
                    value: selectedCity,
                    items: getCityList(),
                    itemToString: (item) => item,
                    borderRadius: 16.r,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.location_city_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22.sp),
                    enabled: selectedCountry != null,
                    onChanged: (val) {
                      setState(() {
                        selectedCity = val;
                      });
                    },
                  ),
                  SizedBox(height: 48.h),
                  Consumer<UserProvider>(
                    builder: (context, userProv, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: userProv.isLoading 
                            ? null 
                            : () async {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) return;

                              if (nameController.text.isEmpty ||
                                  phoneController.text.isEmpty ||
                                  selectedBloodGroup == null ||
                                  selectedCountry == null ||
                                  selectedCity == null) {
                                _showSnackBar(context, 'Please fill all fields', theme.colorScheme.primary);
                                return;
                              }
                              
                              final success = await userProv.updatePersonalInfo(
                                uid: user.uid,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                bloodGroup: selectedBloodGroup!,
                                country: selectedCountry!,
                                city: selectedCity!,
                              );
                              
                              if (success && context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BasicInformation()),
                                );
                              } else if (context.mounted) {
                                _showSnackBar(context, 'Something went wrong', theme.colorScheme.primary);
                              }
                            },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          ),
                          child: userProv.isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.h,
                                child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.5,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}
