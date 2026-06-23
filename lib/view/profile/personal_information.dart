import 'package:blood_donation/core/constants/app_constants.dart';
import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/auth/auth_wrappper.dart';
import 'package:blood_donation/view/profile/basic_information.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PersonelInformation extends StatefulWidget {
  const PersonelInformation({super.key});

  @override
  State<PersonelInformation> createState() => _PersonelInformationState();
}

class _PersonelInformationState extends State<PersonelInformation> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String? selectedBloodGroup;
  String? selectedCountry;
  String? selectedCity;
  bool _loadingExisting = true;

  @override
  void initState() {
    super.initState();
    _prefillExisting();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// A returning user with an incomplete profile is routed back here. Their
  /// Step 1 data is already in Firestore (we write per-step), so load it and
  /// pre-fill the form instead of making them type everything again.
  Future<void> _prefillExisting() async {
    final uid = user?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingExisting = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        nameController.text = (data['name'] ?? '') as String;
        phoneController.text = (data['phone'] ?? '') as String;

        final bg = data['bloodGroup'];
        if (bg is String && bloodGroups.contains(bg)) selectedBloodGroup = bg;

        final country = data['country'];
        if (country is String && countries.contains(country)) {
          selectedCountry = country;
          final city = data['city'];
          // Only restore the city if it's valid for this country, otherwise
          // the dropdown would assert on a value that isn't in its items.
          if (city is String && getCityList().contains(city)) {
            selectedCity = city;
          }
        }
      }
    } catch (_) {
      // Non-fatal: fall back to an empty form the user can fill in.
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  // Blood groups and the country→cities map come from the single app-wide
  // source (app_constants) so the value a donor saves here is always selectable
  // on the create-request side — otherwise city/group could never match and the
  // notification functions would silently never fire for them.
  List<String> get bloodGroups => kBloodGroups;

  List<String> get countries => kCountryCities.keys.toList();

  List<String> getCityList() {
    return kCountryCities[selectedCountry] ?? [];
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
                      // Sign out through the provider so AuthProviders.user is
                      // cleared (not left stale), and clear the cached profile.
                      await auth.logout();
                      if (!context.mounted) return;
                      context.read<UserProvider>().clearUser();
                      // The signup path reached here via pushReplacement, which
                      // REPLACED the AuthWrapper root — so popUntil(isFirst)
                      // would no-op and strand the (now signed-out) user on this
                      // dead screen. Rebuild AuthWrapper as the sole route; its
                      // auth stream then renders LoginScreen.
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
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
      body: _loadingExisting
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    CustomTextField(
                      controller: phoneController,
                      hintText: "Mobile Number",
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_android_rounded,
                      borderRadius: 16.r,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.length < 10) {
                          return 'Enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32.h),
                    _buildSectionTitle('Location & Health', theme),
                    SizedBox(height: 16.h),
                    CustomDropdownFormField<String>(
                      hintText: 'Select Blood Group',
                      value: selectedBloodGroup,
                      items: bloodGroups,
                      itemToString: (item) => item,
                      borderRadius: 16.r,
                      focusedBorderColor: theme.colorScheme.primary,
                      prefixIcon: Icon(Icons.bloodtype_rounded, color: theme.colorScheme.primary.withValues(alpha: 0.6), size: 22.sp),
                      validator: (value) => value == null ? 'Please select blood group' : null,
                      onChanged: (value) {
                        setState(() {
                          selectedBloodGroup = value;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    CustomDropdownFormField<String>(
                      hintText: 'Select Country',
                      value: selectedCountry,
                      items: countries,
                      itemToString: (item) => item,
                      borderRadius: 16.r,
                      focusedBorderColor: theme.colorScheme.primary,
                      prefixIcon: Icon(Icons.public_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 22.sp),
                      validator: (value) => value == null ? 'Please select country' : null,
                      onChanged: (val) {
                        setState(() {
                          selectedCountry = val;
                          selectedCity = null;
                        });
                      },
                    ),
                    SizedBox(height: 16.h),
                    CustomDropdownFormField<String>(
                      hintText: 'Select City',
                      value: selectedCity,
                      items: getCityList(),
                      itemToString: (item) => item,
                      borderRadius: 16.r,
                      focusedBorderColor: theme.colorScheme.primary,
                      prefixIcon: Icon(Icons.location_city_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 22.sp),
                      enabled: selectedCountry != null,
                      validator: (value) => value == null ? 'Please select city' : null,
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
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                
                                final success = await userProv.updatePersonalInfo(
                                  uid: user.uid,
                                  name: nameController.text.trim(),
                                  phone: phoneController.text.trim(),
                                  bloodGroup: selectedBloodGroup!,
                                  country: selectedCountry!,
                                  city: selectedCity!,
                                );
                                
                                if (!context.mounted) return;
                                if (success) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const BasicInformation()),
                                  );
                                } else {
                                  final err = userProv.error;
                                  final lower = (err ?? '').toLowerCase();
                                  final isNetwork = lower.contains('unavailable') ||
                                      lower.contains('network');
                                  _showSnackBar(
                                    context,
                                    isNetwork
                                        ? 'No internet connection. Check your network and try again.'
                                        : 'Could not save your details. Please try again.',
                                    theme.colorScheme.error,
                                  );
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
                              : Text(
                                  'Continue',
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
