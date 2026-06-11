import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/home/home_screen.dart';
import 'package:blood_donation/view/inbox_screen.dart';
import 'package:blood_donation/view/more_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/view/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Tab indices, so callers don't use magic numbers.
  static const int tabHome = 0;
  static const int tabRequests = 1;
  static const int tabSearch = 2;
  static const int tabInbox = 3;
  static const int tabMore = 4;

  static _MainScreenState? _active;

  /// Switch the bottom-nav tab from anywhere inside the main shell
  /// (e.g. Home's "See all" jumps to the Requests tab instead of pushing
  /// a duplicate screen on top of it).
  static void switchTab(int index) => _active?._setTab(index);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    MainScreen._active = this;
  }

  @override
  void dispose() {
    if (MainScreen._active == this) MainScreen._active = null;
    super.dispose();
  }

  void _setTab(int index) {
    if (!mounted || index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  final List<Widget> _pages = [
    HomeScreen(key: HomeScreen.homeKey),
    const BloodrequestScreen(),
    const SearchScreen(),
    const UsersScreen(),
    const MoreScreen(),
  ];

  void _onTap(int index) {
    if (_currentIndex == index && index == 0) {
      // Tapping Home while already on Home scrolls back to top.
      HomeScreen.homeKey.currentState?.scrollToTop();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        // Quick entry point for posting a request, shown only on the Requests
        // tab where it's most contextually relevant.
        floatingActionButton: _currentIndex == MainScreen.tabRequests
            ? _NewRequestButton()
            : null,
        bottomNavigationBar: _NavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

class _NewRequestButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
      ),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 3,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'New request',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26.r),
          topRight: Radius.circular(26.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.water_drop_outlined,
              activeIcon: Icons.water_drop_rounded,
              label: 'Requests',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.search_outlined,
              activeIcon: Icons.search_rounded,
              label: 'Search',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'Inbox',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
              badgeStream: context.read<MessageProvider>().getTotalUnreadCount(),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              selected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeStream,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Stream<int>? badgeStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.45);
    final color = selected ? primary : muted;

    final Widget baseIcon = Icon(selected ? activeIcon : icon, size: 23.sp, color: color);

    final Widget iconWidget = badgeStream == null
        ? baseIcon
        : StreamBuilder<int>(
            stream: badgeStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count <= 0) return baseIcon;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  baseIcon,
                  Positioned(
                right: -7,
                top: -5,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  constraints: BoxConstraints(minWidth: 15.w),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                    ),
                  ),
                ],
              );
            },
          );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: iconWidget,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
