import 'package:blood_donation/view/home/home_screen.dart';
import 'package:blood_donation/view/more_screen.dart';
import 'package:blood_donation/view/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> pages = const [HomeScreen(), SearchScreen(), MoreScreen()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.colorScheme.surface,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
              selectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.sp,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11.sp,
              ),
              elevation: 0,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.home_outlined, size: 24.sp),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.home_rounded, size: 24.sp),
                    ),
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.search_outlined, size: 24.sp),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.search_rounded, size: 24.sp),
                    ),
                  ),
                  label: "Search",
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Icon(Icons.grid_view_outlined, size: 24.sp),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.grid_view_rounded, size: 24.sp),
                    ),
                  ),
                  label: "More",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
