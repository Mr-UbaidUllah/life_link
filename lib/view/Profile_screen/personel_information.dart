import 'package:blood_donation/Provider/auth_provider.dart';
import 'package:blood_donation/Provider/user_provider.dart';
import 'package:blood_donation/view/Profile_screen/basic_information.dart';
import 'package:blood_donation/view/auth%20_screens.dart/login_screen.dart';
import 'package:blood_donation/widgets/custom_dropdown_form_field.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/dropdownheader.dart';
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
    // final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final authProvider = context.read<AuthProviders>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Consumer<AuthProviders>(
          builder: (BuildContext context, auth, Widget? child) {
            return InkWell(
              onTap: auth.isLoading
                  ? null
                  : () async{
                                  await FirebaseAuth.instance.signOut();

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                      // if (context.mounted) {
                      //   // Navigator.pop(context);
                      // }
                    },
              child: Icon(Icons.arrow_back_ios_new_outlined),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.grey, thickness: 0.5),
            SizedBox(height: height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: height * 0.02),
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
              padding: EdgeInsets.symmetric(horizontal: height * 0.02),
              child: Text(
                'Almost Done to set your profile,fill up below\ninformation, its easy just 3 steps',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            ),
            SizedBox(height: height * 0.02),

            Divider(color: Colors.grey, thickness: 0.5.h),

            profileContainer(height: height, icon: Icons.person_2_outlined),
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
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: nameController,
                    focusedBorderColor: Colors.red,
                    labelText: "Your Name",
                    keyboardType: TextInputType.name,
                  ),
                  SizedBox(height: 10.h),

                  CustomTextField(
                    focusedBorderColor: Colors.red,
                    controller: phoneController,
                    labelText: "Mobile Number",
                    keyboardType: TextInputType.phone,
                  ),

                  Dropdownheader(name: 'Select Group'),

                  // header(name: 'Your Name'),

                  // header(name: 'Mobile Number'),
                  // SizedBox(height: 20.h),

                  // CustomDropdown(
                  //   hint: 'Blood Group',
                  //   items: bloodGroups,
                  //   selectedValue: selectedBloodGroup,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       selectedBloodGroup = value;
                  //     });
                  //   },
                  // ),
                  CustomDropdownFormField(
                    hintText: 'Select Blood Group',

                    suffixIcon: const Icon(
                      Icons.keyboard_arrow_down,
                    ), // IMPORTANT

                    value: selectedBloodGroup,
                    items: bloodGroups,
                    itemToString: (item) => item,
                    onChanged: (value) {
                      setState(() {
                        selectedBloodGroup = value;
                      });
                    },
                  ),

                  Dropdownheader(name: 'Select Your country'),
                  CustomDropdownFormField(
                    hintText: 'Select Your Country',
                    value: selectedCountry,
                    items: countries,
                    itemToString: (item) => item,
                    onChanged: (val) {
                      setState(() {
                        selectedCountry = val;
                      });
                    },
                  ),

                  Dropdownheader(name: 'Select Your City'),
                  CustomDropdownFormField(
                    value: selectedCity,
                    items: getCityList(),
                    itemToString: (item) => item,
                    hintText: 'Enter Your City',
                     onChanged: (val) {
                      setState(() {
                        selectedCity = val;
                      });
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Dropdownheader(name: 'Country '),
                  // CustomDropdown(
                  //   hint: 'Select Country',
                  //   items: countries,
                  //   selectedValue: selectedCountry,
                  //   onChanged: (val) {
                  //     setState(() {
                  //       selectedCountry = val;
                  //     });
                  //   },
                  // ),
                  // Dropdownheader(name: 'City '),
                  // CustomDropdown(
                  //   hint: 'Select City',
                  //   items: getCityList(),
                  //   selectedValue: selectedCity,
                  //   onChanged: (val) {
                  //     setState(() {
                  //       selectedCity = val;
                  //     });
                  //   },
                  // ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Consumer<UserProvider>(
                builder: (BuildContext context, User, Widget? child) {
                  return InkWell(
                    onTap: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      if (nameController.text.isEmpty ||
                          phoneController.text.isEmpty ||
                          selectedBloodGroup == null ||
                          selectedCountry == null ||
                          selectedCity == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }
                      final success = await User.updatePersonalInfo(
                        uid: user.uid,
                        name: nameController.text,
                        phone: phoneController.text,
                        bloodGroup: selectedBloodGroup!,
                        country: selectedCountry!,
                        city: selectedCity!,
                      );
                      if (success && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => BasicInformation()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Something went wrong')),
                        );
                      }

                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => BasicInformation(),
                      //   ),
                      // );
                    },
                    child: ReusableButton(label: 'Next'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class profileContainer extends StatelessWidget {
  const profileContainer({super.key, required this.height, required this.icon});

  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.11,
      // width: width * 0.20,v
      decoration: BoxDecoration(color: Colors.red[100], shape: BoxShape.circle),
      child: Center(
        child: Icon(icon, size: height * 0.05, color: Colors.red),
      ),
    );
  }
}
