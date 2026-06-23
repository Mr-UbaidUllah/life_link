import 'package:blood_donation/provider/chat_provider.dart';
import 'package:blood_donation/theme/theme.dart';
import 'package:blood_donation/view/bloodrequest_screen.dart';
import 'package:blood_donation/view/home/home_screen.dart';
import 'package:blood_donation/view/inbox_screen.dart';
import 'package:blood_donation/view/more_screen.dart';
import 'package:blood_donation/view/request_screen.dart';
import 'package:blood_donation/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Tab indices, so callers don't use magic numbers.
  /// Notifications live behind the Home bell.
  static const int tabHome = 0;
  static const int tabRequests = 1;
  static const int tabInbox = 2;
  static const int tabSettings = 3;

  static _MainScreenState? _active;

  /// Switch the bottom-nav tab from anywhere inside the main shell.
  static void switchTab(int index) => _active?._setTab(index);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Cache the unread-count stream once (a new call opens a fresh subscription).
  late final Stream<int> _unreadStream;

  @override
  void initState() {
    super.initState();
    MainScreen._active = this;
    _unreadStream = context.read<MessageProvider>().getTotalUnreadCount();
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
    const BloodRequestScreen(),
    const UsersScreen(),
    const MoreScreen(),
  ];

  void _onTap(int index) {
    if (_currentIndex == index && index == MainScreen.tabHome) {
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
        extendBody: true,
        body: IndexedStack(index: _currentIndex, children: _pages),
        floatingActionButton: const _NewRequestFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _NavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          unreadStream: _unreadStream,
        ),
      ),
    );
  }
}

/// Center gradient FAB — the global "New Request" action, raised above the bar.
class _NewRequestFab extends StatelessWidget {
  const _NewRequestFab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
      ),
      child: Container(
        height: 60.r,
        width: 60.r,
        decoration: BoxDecoration(
          gradient: AppGradients.hero,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.surface, width: 4),
          boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.5),
        ),
        child: Icon(Icons.add_rounded, color: Colors.white, size: 32.sp),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.currentIndex,
    required this.onTap,
    required this.unreadStream,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Stream<int> unreadStream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl.r)),
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                selected: currentIndex == MainScreen.tabHome,
                onTap: () => onTap(MainScreen.tabHome),
              ),
              _NavItem(
                icon: Icons.bloodtype_outlined,
                activeIcon: Icons.bloodtype_rounded,
                label: 'Requests',
                selected: currentIndex == MainScreen.tabRequests,
                onTap: () => onTap(MainScreen.tabRequests),
              ),
              // Gap for the centered FAB.
              SizedBox(width: 64.w),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Inbox',
                selected: currentIndex == MainScreen.tabInbox,
                onTap: () => onTap(MainScreen.tabInbox),
                badgeStream: unreadStream,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                selected: currentIndex == MainScreen.tabSettings,
                onTap: () => onTap(MainScreen.tabSettings),
              ),
            ],
          ),
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
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final color = selected ? primary : muted;

    final Widget plainIcon =
        Icon(selected ? activeIcon : icon, size: 24.sp, color: color);

    final Widget iconWidget = badgeStream == null
        ? plainIcon
        : StreamBuilder<int>(
            stream: badgeStream,
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              if (count <= 0) return plainIcon;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  plainIcon,
                  Positioned(
                    right: -7,
                    top: -5,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      constraints: BoxConstraints(minWidth: 15.w),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(AppRadii.pill.r),
                        border: Border.all(
                            color: theme.colorScheme.surface, width: 1.5),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w800),
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
            // Floating tab indicator that grows in under the active item.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3.h,
              width: selected ? 22.w : 0,
              margin: EdgeInsets.only(bottom: 7.h),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(AppRadii.pill.r),
              ),
            ),
            AnimatedScale(
              scale: selected ? 1.0 : 0.92,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: iconWidget,
            ),
            SizedBox(height: 4.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                color: color,
                fontSize: 10.5.sp,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
              child: Text(label, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}
