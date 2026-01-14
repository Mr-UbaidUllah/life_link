import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/view/profile/personel_information.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/redContainer.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  TextEditingController phone_controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [redContainer(height: height, width: width)],
            ),

            Positioned(
              left: width * 0.05,
              right: width * 0.05,
              top: height * 0.2,
              child: Container(
                height: height * 0.30,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    CustomTextField(
                      focusedBorderColor: Colors.red,
                      controller: email_controller,
                      hintText: 'Email',
                      prefixIcon: Icons.mail,
                    ),
                    SizedBox(height: height * 0.03),
                    CustomTextField(
                      focusedBorderColor: Colors.red,
                      controller: password_controller,
                      prefixIcon: Icons.lock,
                      hintText: 'Password',
                    ),
                    // SizedBox(height: height * 0.02),
                    // ReusableTextField(
                    //   hintText: 'Phone Number',
                    //   icon: Icons.phone,
                    //   controller: phone_controller,
                    // ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: width * 0.05,
              right: width * 0.05,
              top: height * 0.45,
              child: Selector<AuthProviders, bool>(
                selector: (_, auth) => auth.isLoading,
                builder: (context, isLoading, _) {
                  return InkWell(
                    onTap: isLoading
                        ? null
                        : () async {
                            final auth = context.read<AuthProviders>();

                            try {
                              await auth.signup(
                                email_controller.text.trim(),
                                password_controller.text.trim(),
                              );

                              if (!context.mounted) return;

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => PersonelInformation(),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : ReusableButton(label: 'Sign up'),
                  );
                },
              ),
            ),

            // // SIGN UP BUTTON
            // Positioned(
            //   left: width * 0.05,
            //   right: width * 0.05,
            //   top: height * 0.45,
            //   child: Consumer<AuthProviders>(
            //     builder:
            //         (BuildContext context, AuthProviders auth, Widget? child) {
            //           return InkWell(
            //             onTap: auth.isLoading
            //                 ? null
            //                 : () async {
            //                     try {
            //                       await auth.Signup(
            //                         email_controller.text.trim(),
            //                         password_controller.text.trim(),
            //                       );

            //                       // ✅ SUCCESS → Navigate
            //                       Navigator.push(
            //                         context,
            //                         MaterialPageRoute(
            //                           builder: (_) => PersonelInformation(),
            //                         ),
            //                       );
            //                     } catch (e) {
            //                       ScaffoldMessenger.of(context).showSnackBar(
            //                         SnackBar(
            //                           content: Text('Signupo failed'),
            //                           backgroundColor: Colors.red,
            //                         ),
            //                       );
            //                     }
            //                   },
            //             child: auth.isLoading
            //                 ? const CircularProgressIndicator()
            //                 : ReusableButton(label: 'Sign up'),
            //           );
            //         },
            //   ),
            // ),
            Positioned(
              top: height * 0.60, //
              left: 0,
              right: 0,
              child: Center(
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
