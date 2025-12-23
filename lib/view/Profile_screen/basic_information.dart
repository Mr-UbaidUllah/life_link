import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/Profile_screen/image_screen.dart';
import 'package:blood_donation/view/Profile_screen/personel_information.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/dropdownheader.dart';
import 'package:blood_donation/widgets/header.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class BasicInformation extends StatefulWidget {
  const BasicInformation({super.key});

  @override
  State<BasicInformation> createState() => _BasicInformationState();
}

class _BasicInformationState extends State<BasicInformation> {
  String? selectedGender;
  String? selectedOption;
  final List<String> Genders = ['Male', 'Female', 'Others'];
  final List<String> Options = ['Yes', 'No'];
  final TextEditingController dateController = TextEditingController();
  final TextEditingController aboutcontroller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Divider(color: Colors.grey, thickness: 0.5),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Text(
                'Profile Setup',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.h,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Text(
                'Almost Done to set your profile,fill up below\ninformation, its easy just 3 steps',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            SizedBox(height: 20.h),

            Divider(color: Colors.grey, thickness: 0.5.h),

            profileContainer(
              height: 900.h,
              icon: Icons.perm_device_information_outlined,
            ),
            SizedBox(height: 10.h),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Personel Information',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    readOnly: true,
                    controller: dateController,
                    hintText: 'Select Date',
                    labelText: 'Date of Birth ',
                    focusedBorderColor: Colors.red,
                    suffixIcon: Icon(Icons.calendar_month),
                    onTap: () async {
                      DateTime? pickDate = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2100),
                      );
                      if (pickDate != null) {
                        dateController.text =
                            "${pickDate.day}/${pickDate.month}/${pickDate.year}";
                      }
                    },
                  ),
                  Dropdownheader(name: 'Gender'),
                  CustomDropdownFormField(
                    hintText: 'Select gender',
                    value: selectedGender,
                    items: Genders,
                    itemToString: (item) => item,
                    onChanged: (val) {
                      setState(() {
                        selectedGender = val;
                      });
                    },
                  ),
                  Dropdownheader(name: 'I want to donate blood'),
                  CustomDropdownFormField(
                    value: selectedOption,
                    items: Options,
                    itemToString: (items) => items,
                    onChanged: (val) {
                      selectedOption = val;
                    },
                  ),
                  // Dropdownheader(name: 'About yourself'),
                  CustomTextField(
                    hintText: 'Type about yourself',
                    focusedBorderColor: Colors.red,
                    labelText: "About Your Self",
                    maxLines: 7,
                    controller: aboutcontroller,
                  ),
                  SizedBox(height: 20.h),
                  Consumer<UserProvider>(
                    builder:
                        (
                          BuildContext context,
                          UserProvider users,
                          Widget? child,
                        ) {
                          return GestureDetector(
                            onTap: () async {
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User not logged in'),
                                  ),
                                );
                                return;
                              }

                              if (dateController.text.isEmpty ||
                                  selectedGender == null ||
                                  selectedOption == null ||
                                  aboutcontroller.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all fields'),
                                  ),
                                );
                                return;
                              }

                              // Update basic info
                              final success = await users.updateBasicInfo(
                                uid: user.uid,
                                dateOfBirth: dateController.text.trim(),
                                gender: selectedGender!,
                                wantToDonate: selectedOption!,
                                about: aboutcontroller.text.trim(),
                              );

                              // ✅ Update profileCompleted field
                              if (success) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'profileCompleted': true});
                              }

                              // Navigate to next screen
                              if (success && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageScreen(),
                                  ),
                                );
                              }
                            },
                            child: ReusableButton(label: 'Next'),
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
