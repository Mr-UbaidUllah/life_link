import 'package:blood_donation/view/auth/onboarding_Screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // SvgIcon('assets/images/water.svg', color: Colors.amber, height: 20),
            Image.asset('assets/images/water 1.png'),
            Text(
              'Blood Care',
              style: TextStyle(color: Colors.white, fontSize: 48),
            ),
          ],
        ),
      ),
    );
  }
}
