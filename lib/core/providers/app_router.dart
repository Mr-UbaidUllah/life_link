import 'package:blood_donation/core/constants/route_constants.dart';
import 'package:blood_donation/splash_screen.dart';
import 'package:blood_donation/view/auth/auth_wrappper.dart';
import 'package:blood_donation/view/auth/login_screen.dart';
import 'package:blood_donation/view/auth/signup_screen.dart';
import 'package:blood_donation/view/bottmNavigation.dart';
import 'package:blood_donation/view/profile/personel_information.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: RouteConstants.splash,
    routes: [
      GoRoute(
        path: RouteConstants.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteConstants.authWrapper,
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: RouteConstants.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteConstants.home,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: RouteConstants.personnelInfo,
        builder: (context, state) => const PersonelInformation(),
      ),
    ],
  );
}
