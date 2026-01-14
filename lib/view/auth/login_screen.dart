import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/view/auth/signup_screen.dart';
import 'package:blood_donation/view/auth_wrappper.dart';
import 'package:blood_donation/widgets/redContainer.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:blood_donation/widgets/reusable_email.dart';
import 'package:blood_donation/widgets/reusable_password.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
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
              height: height * 0.40,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ReusableTextField(
                    hintText: 'Email',
                    icon: Icons.email,
                    controller: email_controller,
                  ),
                  SizedBox(height: height * 0.03),
                  ReuseablePasswordfield(
                    hintText: 'Password',
                    prefixIcon: Icons.lock,
                    controller: password_controller,
                  ),
                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
          ),

          // SIGN UP BUTTON
          Positioned(
            left: width * 0.05,
            right: width * 0.05,
            top: height * 0.55,
            child: Consumer<AuthProviders>(
              builder: (BuildContext context, auth, Widget? child) {
                return InkWell(
                  onTap: auth.isLoading
                      ? null
                      : () async {
                          try {
                            await auth.login(
                              email_controller.text.trim(),
                              password_controller.text.trim(),
                            );

                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => AuthWrapper(),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: auth.isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : ReusableButton(label: 'Login'),
                );
              },
            ),
          ),

          Positioned(
            top: height * 0.72, //
            left: 0,
            right: 0,
            child: Center(
              child: RichText(
                text: TextSpan(
                  text: 'Dont have an account',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
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
                              builder: (context) => SignupScreen(),
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
    );
  }
}
