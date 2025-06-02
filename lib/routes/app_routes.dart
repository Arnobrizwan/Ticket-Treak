// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:ticket_trek/screens/user/booking/booking_detail_screen.dart';
import 'package:ticket_trek/screens/user/booking/cancel_booking_screen.dart';
import 'package:ticket_trek/screens/user/booking/my_bookings_screen.dart';
import 'package:ticket_trek/screens/user/booking/refund_status_screen.dart';
import '../screens/user/splash/splash_screen.dart';

// Import screens
import '../screens/user/onboarding/onboarding_screen.dart';
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';
import '../screens/user/dashboard/home_dashboard.dart';
import '../screens/user/flight/flight_search_page.dart';
// import '../screens/user/auth/edit_profile_screen.dart'; // Your real EditProfileScreen, if/when you implement it

class AppRoutes {
  // ─── Route Names ───────────────────────────────────────────────────────────
  static const String splash              = '/';
  static const String onboarding          = '/onboarding';
  static const String login               = '/login';
  static const String register            = '/register';
  static const String passwordReset       = '/password-reset';
  static const String homeDashboard       = '/home-dashboard';
  static const String searchFlight        = '/search-flight';
  static const String myBookings          = '/my-bookings';
  static const String bookingDetail       = '/booking-detail';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String cancelBooking       = '/cancel-booking';
  static const String refundStatus        = '/refund-status';

  // Re-added editProfile so HomeDashboard’s calls to AppRoutes.editProfile compile:
  static const String editProfile         = '/edit-profile';

  // ─── “Enterprise” / Extra Routes ────────────────────────────────────────────
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

    // HomeDashboard (passing a dummy userName for now; you can override as needed)
    homeDashboard: (context) => const HomeDashboard(userName: "John Doe"),

    searchFlight: (context) => const FlightSearchPage(),
    myBookings: (context) => const MyBookingsScreen(),
    bookingDetail: (context) => BookingDetailScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
    bookingConfirmation: (context) => Scaffold(
          body: Center(child: Text('Booking Confirmation Screen Placeholder')),
        ),
    cancelBooking: (context) => CancelBookingScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
    refundStatus: (context) => RefundStatusScreen(
          bookingId: ModalRoute.of(context)!.settings.arguments as String,
        ),

    // ─── Edit Profile (placeholder) ───────────────────────────────────────────
    editProfile: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: const Center(
            child: Text(
              'EditProfileScreen has not been implemented yet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),

    // ─── “Enterprise” placeholders (because AppBar cannot be a const) ────────────
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