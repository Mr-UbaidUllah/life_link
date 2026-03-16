import 'package:blood_donation/provider/user_provider.dart';
import 'package:blood_donation/view/profile/image_screen.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BasicInformation extends StatefulWidget {
  const BasicInformation({super.key});

  @override
  State<BasicInformation> createState() => _BasicInformationState();
}

class _BasicInformationState extends State<BasicInformation> {
  String? selectedGender;
  String? selectedOption;
  final List<String> genders = ['Male', 'Female', 'Others'];
  final List<String> options = ['Yes', 'No'];
  final TextEditingController dateController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  @override
  void dispose() {
    dateController.dispose();
    aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile Setup',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 80, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Step 2 of 3',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Health Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    readOnly: true,
                    controller: dateController,
                    hintText: 'Date of Birth',
                    prefixIcon: Icons.calendar_month_outlined,
                    borderRadius: 12,
                    onTap: () async {
                      DateTime? pickDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: theme.colorScheme,
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickDate != null) {
                        setState(() {
                          dateController.text =
                              "${pickDate.day}/${pickDate.month}/${pickDate.year}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownFormField(
                    hintText: 'Select Gender',
                    value: selectedGender,
                    items: genders,
                    itemToString: (item) => item,
                    borderRadius: 12,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.person_outline, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    onChanged: (val) {
                      setState(() {
                        selectedGender = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Donation Preference',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomDropdownFormField(
                    hintText: 'I want to donate blood',
                    value: selectedOption,
                    items: options,
                    itemToString: (item) => item,
                    borderRadius: 12,
                    focusedBorderColor: theme.colorScheme.primary,
                    prefixIcon: Icon(Icons.volunteer_activism_outlined, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    onChanged: (val) {
                      setState(() {
                        selectedOption = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Tell us a bit about yourself...',
                    labelText: "About Yourself",
                    maxLines: 4,
                    borderRadius: 12,
                    controller: aboutController,
                  ),
                  const SizedBox(height: 40),
                  Consumer<UserProvider>(
                    builder: (context, users, _) {
                      return InkWell(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) return;

                          if (dateController.text.isEmpty ||
                              selectedGender == null ||
                              selectedOption == null ||
                              aboutController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please fill all fields'),
                                backgroundColor: theme.colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final success = await users.updateBasicInfo(
                            uid: user.uid,
                            dateOfBirth: dateController.text.trim(),
                            gender: selectedGender!,
                            wantToDonate: selectedOption!,
                            about: aboutController.text.trim(),
                          );

                          if (success && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const ImageScreen()),
                            );
                          }
                        },
                        child: users.isLoading 
                          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                          : const ReusableButton(label: 'Next'),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
