import 'package:blood_donation/provider/auth_provider.dart';
import 'package:blood_donation/view/auth/signup_screen.dart';
import 'package:blood_donation/view/auth/auth_wrappper.dart';
import 'package:blood_donation/widgets/custom_text_field.dart';
import 'package:blood_donation/widgets/redContainer.dart';
import 'package:blood_donation/widgets/reusable_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email_controller = TextEditingController();
  final TextEditingController password_controller = TextEditingController();

  @override
  void dispose() {
    email_controller.dispose();
    password_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                redContainer(height: height, width: width),
                Padding(
                  padding: EdgeInsets.only(top: height * 0.3),
                  child: Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to continue saving lives',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextField(
                          controller: email_controller,
                          hintText: 'Email Address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          borderRadius: 12,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          controller: password_controller,
                          prefixIcon: Icons.lock_outline,
                          hintText: 'Password',
                          isPassword: true,
                          borderRadius: 12,
                        ),
                        const SizedBox(height: 40),
                        Consumer<AuthProviders>(
                          builder: (context, auth, _) {
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
                                            backgroundColor: theme.colorScheme.error,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              child: auth.isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : const ReusableButton(label: 'Login'),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
