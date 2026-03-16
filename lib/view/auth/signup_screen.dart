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
  final TextEditingController email_controller = TextEditingController();
  final TextEditingController password_controller = TextEditingController();
  final TextEditingController phone_controller = TextEditingController();

  @override
  void dispose() {
    email_controller.dispose();
    password_controller.dispose();
    phone_controller.dispose();
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
                          'Create Account',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign up to join our life-saving community',
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
                        Selector<AuthProviders, bool>(
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
                                            builder: (_) => const PersonelInformation(),
                                          ),
                                        );
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
                              child: isLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  : const ReusableButton(label: 'Sign up'),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
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
                                          builder: (context) => const LoginScreen(),
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
