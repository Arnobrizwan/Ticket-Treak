// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import '../screens/user/splash/splash_screen.dart';

// Future Screens (currently commented out)
 import '../screens/user/onboarding/onboarding_screen.dart';
 import '../screens/user/auth/login_screen.dart';
 import '../screens/user/auth/register_screen.dart';
 import '../screens/user/auth/password_reset_screen.dart';
// import '../screens/user/dashboard/home_dashboard.dart';
// import '../screens/user/flight/flight_search_screen.dart';
// import '../screens/user/flight/saved_flights_screen.dart';
// import '../screens/user/flight/flight_results_screen.dart';
// import '../screens/user/flight/flight_detail_screen.dart';

class AppRoutes {
  static const String splash = '/';

   static const String onboarding = '/onboarding';
   static const String login = '/login';
   static const String register = '/register';
   static const String passwordReset = '/password-reset';
  // static const String dashboard = '/dashboard';
  // static const String flightSearch = '/flight-search';
  // static const String savedFlights = '/saved-flights';
  // static const String flightResults = '/flight-results';
  // static const String flightDetail = '/flight-detail';

  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),

     onboarding: (context) => const OnboardingScreen(),
    AppRoutes.login: (context) => const LoginScreen(),
AppRoutes.register: (context) => const RegisterScreen(),
AppRoutes.passwordReset: (context) => const PasswordResetScreen(),
    // dashboard: (context) => const HomeDashboard(),
    // flightSearch: (context) => const FlightSearchScreen(),
    // savedFlights: (context) => const SavedFlightsScreen(),
    // flightResults: (context) => const FlightResultsScreen(),
    // flightDetail: (context) => const FlightDetailScreen(),
  };
}
