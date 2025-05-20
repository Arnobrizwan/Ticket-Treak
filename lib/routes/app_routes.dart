import 'package:flutter/material.dart';
import '../screens/user/splash/splash_screen.dart';
// Import screens
import '../screens/user/onboarding/onboarding_screen.dart';
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';
import '../screens/user/dashboard/home_dashboard.dart';
import '../screens/user/flight/flight_search_page.dart'; // Updated import path for the new page

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
  
  // Remove duplicate route - you had both searchFlight and flightSearch defined
  // static const String flightSearch = '/flight-search';
  
  // static const String savedFlights = '/saved-flights';
  // static const String flightResults = '/flight-results';
  // static const String flightDetail = '/flight-detail';
  
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    passwordReset: (context) => const PasswordResetScreen(),
    
    // Fix the HomeDashboard constructor by providing the required userName parameter
    dashboard: (context) => const HomeDashboard(userName: "John Doe"), // Provide a default or get from shared preferences
    
    // Use the correct class name FlightSearchPage instead of FlightSearchScreen
    searchFlight: (context) => const FlightSearchPage(),
    
    // Other routes can be uncommented as you implement them
    // savedFlights: (context) => const SavedFlightsScreen(),
    // flightResults: (context) => const FlightResultsScreen(),
    // flightDetail: (context) => const FlightDetailScreen(),
  };
}