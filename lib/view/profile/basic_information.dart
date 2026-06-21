import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class BasicInformation extends StatefulWidget {
  /// When true, this screen is being used to EDIT an already-onboarded user's
  /// health details (opened from Settings) rather than as Step 2 of the
  /// first-time setup wizard. In edit mode saving pops back to the caller
  /// instead of advancing to the photo step + wiping the nav stack.
  final bool isEditMode;

  const BasicInformation({super.key, this.isEditMode = false});

  @override
  State<BasicInformation> createState() => _BasicInformationState();
}

class _BasicInformationState extends State<BasicInformation> {
  String? selectedOption;
  final List<String> options = ['Yes', 'No'];
  final TextEditingController aboutController = TextEditingController();
  bool _loadingExisting = true;

  @override
  void initState() {
    super.initState();
    _prefillExisting();
  }

  @override
  void dispose() {
    aboutController.dispose();
    super.dispose();
  }

  /// Restore previously saved Step 2 values for a returning user so they don't
  /// have to re-enter them.
  Future<void> _prefillExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loadingExisting = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        if (data['isDonor'] is bool) {
          selectedOption = (data['isDonor'] as bool) ? 'Yes' : 'No';
        }
        aboutController.text = (data['about'] ?? '') as String;
      }
    } catch (_) {
      // Non-fatal: fall back to an empty form.
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  // The provider stores errors as e.toString(); Firestore network failures
  // surface as "[cloud_firestore/unavailable]" or contain "network".
  bool _isNetworkError(String? error) {
    if (error == null) return false;
    final lower = error.toLowerCase();
    return lower.contains('unavailable') || lower.contains('network');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        // Only show a back button when there's actually a previous step to
        // return to. When this screen is the resumed entry point (rendered
        // directly by AuthWrapper) nothing is on the stack, so a back button
        // would be a dead control — hide it instead.
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          widget.isEditMode ? 'Update Health Details' : 'Profile Setup',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _loadingExisting
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 80.sp, color: theme.colorScheme.primary),
                  SizedBox(height: 12.h),
                  if (!widget.isEditMode) ...[
                    Text(
                      'Step 2 of 3',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Text(
                    'Health Details',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(24.0.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donation Preference',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomDropdownFormField(
                    hintText: 'I want to donate blood',
                    value: selectedOption,
                    items: options,
                    itemToString: (item) => item,
                    borderRadius: 12,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.volunteer_activism_outlined, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                    onChanged: (val) {
                      setState(() {
                        selectedOption = val;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  CustomTextField(
                    hintText: 'Tell us a bit about yourself...',
                    labelText: "About Yourself (Optional)",
                    maxLines: 4,
                    borderRadius: 12,
                    controller: aboutController,
                  ),
                  SizedBox(height: 40.h),
                  Consumer<UserProvider>(
                    builder: (context, users, _) {
                      return InkWell(
                        // Disable the tap while saving so a fast double-tap
                        // can't fire two updateBasicInfo writes.
                        onTap: users.isLoading
                            ? null
                            : () async {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) return;

                          if (selectedOption == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a donation preference'),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final success = await users.updateBasicInfo(
                            uid: user.uid,
                            wantToDonate: selectedOption!,
                            about: aboutController.text.trim(),
                          );

                          if (!context.mounted) return;
                          if (success) {
                            if (widget.isEditMode) {
                              // Editing from Settings: just return to the caller
                              // with a confirmation — don't advance to the photo
                              // step or wipe the nav stack.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Health details updated'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            } else {
                              // First-time setup: push (not pushReplacement) so the
                              // back stack stays Step1 → Step2 → Step3 and the back
                              // arrow walks it.
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ImageScreen()),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isNetworkError(users.error)
                                      ? 'No internet connection. Check your network and try again.'
                                      : 'Could not save your details. Please try again.',
                                ),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: users.isLoading
                          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                          : ReusableButton(label: widget.isEditMode ? 'Save' : 'Next'),
                      );
                    },
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
