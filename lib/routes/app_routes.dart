import 'package:flutter/material.dart';
import '../screens/user/splash/splash_screen.dart';
// Import screens
import '../screens/user/onboarding/onboarding_screen.dart';
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';
import '../screens/user/dashboard/home_dashboard.dart';
import '../screens/user/flight/flight_search_page.dart';
import '../screens/user/auth/edit_profile_screen.dart'; // Updated path to match your renamed file

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String passwordReset = '/password-reset';
  static const String dashboard = '/dashboard';
  static const String searchFlight = '/search-flight';
  static const String myBookings = '/my-bookings';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    passwordReset: (context) => const PasswordResetScreen(),
    dashboard: (context) => const HomeDashboard(userName: "John Doe"),
    searchFlight: (context) => const FlightSearchPage(),
    editProfile: (context) => const EditProfileScreen(userName: "Arnob"),
  };
}