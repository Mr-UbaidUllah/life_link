import 'package:blood_donation/models/bloodrequest_model.dart';
import 'package:blood_donation/provider/bloodRequest_provider.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  final Map<String, List<String>> countryCities = {
    "Pakistan": ["Peshawar", "Lahore", "Karachi", "Islamabad"],
    "India": ["Delhi", "Mumbai", "Bangalore", "Kolkata"],
    "USA": ["New York", "Los Angeles", "Chicago", "Houston"],
  };

  String? selectedBloodGroup;
  String? selectedCountry;
  String? selectedCity;
  DateTime? selectedDate;

  void _showSnackBar(BuildContext context, ThemeData theme, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
        backgroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: Text(
          "Create Blood Request",
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
            _buildSectionTitle("General Information", theme),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: titleController,
              labelText: "Post Title",
              hintText: "e.g. Urgent O+ Blood Needed",
              prefixIcon: Icons.title_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomDropdownFormField<String>(
              labelText: "Blood Group",
              hintText: "Select Group",
              value: selectedBloodGroup,
              items: bloodGroups,
              itemToString: (e) => e,
              prefixIcon: Icon(Icons.bloodtype_rounded, color: theme.colorScheme.primary, size: 22.sp),
              onChanged: (val) => setState(() => selectedBloodGroup = val),
              focusedBorderColor: theme.colorScheme.primary,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: amountController,
              labelText: "Units/Bags Needed",
              hintText: "Type number of bags",
              keyboardType: TextInputType.number,
              prefixIcon: Icons.opacity_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            _buildDateField(theme),
            SizedBox(height: 24.h),

            _buildSectionTitle("Medical Details", theme),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: hospitalController,
              labelText: "Hospital Name",
              hintText: "Type hospital name",
              prefixIcon: Icons.local_hospital_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: reasonController,
              labelText: "Reason for Request",
              hintText: "Explain the emergency...",
              maxLines: 3,
              prefixIcon: Icons.info_outline_rounded,
              borderRadius: 16.r,
              height: 120.h,
            ),
            SizedBox(height: 24.h),

            _buildSectionTitle("Contact Information", theme),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: contactController,
              labelText: "Contact Person Name",
              hintText: "Full name of contact",
              prefixIcon: Icons.person_outline_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomTextField(
              controller: phoneController,
              labelText: "Mobile Number",
              hintText: "e.g. +92 300 1234567",
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomDropdownFormField<String>(
              labelText: "Country",
              hintText: "Select Country",
              value: selectedCountry,
              items: countryCities.keys.toList(),
              itemToString: (e) => e,
              prefixIcon: Icon(Icons.public_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22.sp),
              onChanged: (val) => setState(() {
                selectedCountry = val;
                selectedCity = null;
              }),
              focusedBorderColor: theme.colorScheme.primary,
              borderRadius: 16.r,
            ),
            SizedBox(height: 16.h),
            CustomDropdownFormField<String>(
              labelText: "City",
              hintText: "Select City",
              value: selectedCity,
              items: selectedCountry == null ? [] : countryCities[selectedCountry] ?? [],
              itemToString: (e) => e,
              prefixIcon: Icon(Icons.location_city_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 22.sp),
              enabled: selectedCountry != null,
              onChanged: (val) => setState(() => selectedCity = val),
              focusedBorderColor: theme.colorScheme.primary,
              borderRadius: 16.r,
            ),

            SizedBox(height: 40.h),

            Consumer<BloodrequestProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) return;

                            final bags = int.tryParse(amountController.text);
                            if (bags == null || bags <= 0) {
                              _showSnackBar(context, theme, "Please enter valid number of bags", isError: true);
                              return;
                            }

                            if (titleController.text.isEmpty ||
                                selectedBloodGroup == null ||
                                hospitalController.text.isEmpty ||
                                selectedCountry == null ||
                                selectedCity == null ||
                                phoneController.text.isEmpty) {
                              _showSnackBar(context, theme, "Please fill all required fields", isError: true);
                              return;
                            }

                            final request = BloodRequestModel(
                              id: '',
                              title: titleController.text.trim(),
                              bloodGroup: selectedBloodGroup ?? '',
                              bags: bags,
                              hospital: hospitalController.text.trim(),
                              reason: reasonController.text.trim(),
                              contactName: contactController.text.trim(),
                              phone: phoneController.text.trim(),
                              country: selectedCountry ?? '',
                              city: selectedCity ?? '',
                              userId: user.uid,
                              createdAt: DateTime.now(),
                              status: 'open',
                            );

                            try {
                              await provider.bloodRequest(request);
                              if (mounted) {
                                _showSnackBar(context, theme, "Request submitted successfully!");
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar(context, theme, e.toString(), isError: true);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    child: provider.isLoading
                        ? SizedBox(
                            height: 24.h,
                            width: 24.h,
                            child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2.5),
                          )
                        : Text(
                            "Submit Request",
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

  Widget _buildDateField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Requirement Date",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: theme.colorScheme,
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => selectedDate = date);
            }
          },
          child: Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: theme.colorScheme.outline, width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    SizedBox(width: 12.w),
                    Text(
                      selectedDate == null
                          ? "Select Date"
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: selectedDate == null ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_drop_down_rounded, size: 24.sp, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
