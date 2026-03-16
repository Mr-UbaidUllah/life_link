import 'package:blood_donation/view/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;
  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/donation.jpg",
      "title": "Donate Blood, Save Lives",
      "subtitle":
          "Your one donation can save up to three lives. Be a real hero today.",
    },
    {
      "image": "assets/images/donation2.jpg",
      "title": "Find Nearby Donors",
      "subtitle": "Quickly connect with donors and patients within minutes.",
    },
    {
      "image": "assets/images/donation3.png",
      "title": "Become a Life Saver",
      "subtitle": "Join the community and help those who need you the most.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(pages[index]['image']!, height: height * 0.4),
                    SizedBox(height: height * 0.03),
                    Text(
                      pages[index]['title']!,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(height * 0.02),
                      child: Text(
                        pages[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(pages.length, (index) => buildDot(index, theme)),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (currentIndex == pages.length - 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              }
            },
            child: Container(
              margin: EdgeInsets.all(height * 0.03),
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.05),
        ],
      ),
    );
  }

  Widget buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: currentIndex == index ? 30 : 10,
      decoration: BoxDecoration(
        color: currentIndex == index ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
