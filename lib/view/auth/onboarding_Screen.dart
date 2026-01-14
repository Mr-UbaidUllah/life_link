import 'package:blood_donation/view/auth/signup_screen.dart';
import 'package:flutter/material.dart';

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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(height * 0.02),
                      child: Text(
                        textAlign: TextAlign.center,
                        pages[index]['subtitle']!,
                        style: TextStyle(fontSize: 14),
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
              ...List.generate(pages.length, (index) => buildDot(index)),
            ],
          ),
          GestureDetector(
            onTap: () {
              if (currentIndex == pages.length - 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignupScreen()),
                );
              } else {
                _controller.nextPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.ease,
                );
              }
            },
            child: Container(
              margin: EdgeInsets.all(height * 0.03),
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: currentIndex == index ? 30 : 10,
      decoration: BoxDecoration(
        color: currentIndex == index ? Colors.redAccent : Colors.grey,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
