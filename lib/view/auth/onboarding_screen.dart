import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/auth/auth_wrappper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 12.w, top: 4.h),
              child: currentIndex == pages.length - 1
                  ? SizedBox(height: 40.h)
                  : TextButton(
                      onPressed: _finishOnboarding,
                      child: Text('Skip',
                          style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                              fontWeight: FontWeight.w700)),
                    ),
            ),
          ),
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Text(
                        pages[index]['title']!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(fontSize: 26.sp),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(32.w, 12.h, 32.w, 0),
                      child: Text(
                        pages[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                _finishOnboarding();
              } else {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              }
            },
            child: Container(
              margin: EdgeInsets.all(height * 0.03),
              height: 55.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.32),
              ),
              child: Center(
                child: Text(
                  currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: height * 0.05),
        ],
      ),
      ),
    );
  }

  Widget buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 5.w),
      height: 10.h,
      width: currentIndex == index ? 30.w : 10.w,
      decoration: BoxDecoration(
        color: currentIndex == index ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
    );
  }
}
