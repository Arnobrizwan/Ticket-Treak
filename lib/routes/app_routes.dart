// lib/routes/app_routes.dart

import 'package:flutter/material.dart';

// Booking screens
import 'package:ticket_trek/screens/user/booking/booking_detail_screen.dart';
import 'package:ticket_trek/screens/user/booking/cancel_booking_screen.dart';
import 'package:ticket_trek/screens/user/booking/my_bookings_screen.dart';
import 'package:ticket_trek/screens/user/booking/refund_status_screen.dart';

// Splash & Onboarding
import '../screens/user/splash/splash_screen.dart';
import '../screens/user/onboarding/onboarding_screen.dart';

// Auth
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';

// Dashboard
import '../screens/user/dashboard/home_dashboard.dart';

// ─── Flight screens ────────────────────────────────────────────────
import '../screens/user/flight/flight_search_page.dart';
import '../screens/user/flight/flight_results_screen.dart';
import '../screens/user/flight/flight_detail_screen.dart';
import '../screens/user/flight/saved_flights_screen.dart';

class AppRoutes {
  // Route names
  static const String splash              = '/';
  static const String onboarding          = '/onboarding';
  static const String login               = '/login';
  static const String register            = '/register';
  static const String passwordReset       = '/password-reset';
  static const String homeDashboard       = '/home-dashboard';

  // Flight flow
  static const String searchFlight        = '/search-flight';
  static const String flightResults       = '/flight-results';
  static const String flightDetail        = '/flight-detail';
  static const String savedFlights        = '/saved-flights';

  // Booking flow
  static const String myBookings          = '/my-bookings';
  static const String bookingDetail       = '/booking-detail';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String cancelBooking       = '/cancel-booking';
  static const String refundStatus        = '/refund-status';

  // Edit Profile placeholder
  static const String editProfile         = '/edit-profile';

  // Enterprise / extra placeholders
  static const String notifications       = '/notifications';
  static const String explore             = '/explore';
  static const String deals               = '/deals';
  static const String groupBooking        = '/group-booking';
  static const String support             = '/support';

  // ─── All Route → WidgetBuilder Map ─────────────────────────────────────────
  static final Map<String, WidgetBuilder> routes = {
    // Core flows
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    passwordReset: (context) => const PasswordResetScreen(),

    // HomeDashboard (passing a dummy userName for now)
    homeDashboard: (context) => const HomeDashboard(userName: "John Doe"),

    // ─── Flight flow
    searchFlight: (context) => const FlightSearchPage(),
    flightResults: (context) => const FlightResultsPage(),
    flightDetail: (context) => const FlightDetailScreen(),
    savedFlights: (context) => const SavedFlightsScreen(),

    // ─── Booking flow
    myBookings: (context) => const MyBookingsScreen(),
    bookingDetail: (context) => BookingDetailScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
    bookingConfirmation: (context) => Scaffold(
          body: Center(
            child: Text('Booking Confirmation Screen Placeholder'),
          ),
        ),
    cancelBooking: (context) => CancelBookingScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
    refundStatus: (context) => RefundStatusScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),

    // ─── EditProfile placeholder (removed `const` here so children don’t all have to be `const`)
    editProfile: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: const Center(
            child: Text(
              'EditProfileScreen has not been implemented yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),

    // ─── “Enterprise” placeholders (remove `const` so we don’t get “non-const constructor” errors)
    notifications: (context) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: const Center(child: Text('Notifications Screen Placeholder')),
        ),
    explore: (context) => Scaffold(
          appBar: AppBar(title: const Text('Explore')),
          body: const Center(child: Text('Explore Screen Placeholder')),
        ),
    deals: (context) => Scaffold(
          appBar: AppBar(title: const Text('Deals')),
          body: const Center(child: Text('Deals Screen Placeholder')),
        ),
    groupBooking: (context) => Scaffold(
          appBar: AppBar(title: const Text('Group Booking')),
          body: const Center(child: Text('Group Booking Screen Placeholder')),
        ),
    support: (context) => Scaffold(
          appBar: AppBar(title: const Text('Support Chat')),
          body: const Center(child: Text('Support Chat Screen Placeholder')),
        ),
  };
}