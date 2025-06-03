// lib/routes/app_routes.dart

import 'package:flutter/material.dart';

// ─── Splash & Onboarding ─────────────────────────────────────────────────────
import '../screens/user/splash/splash_screen.dart';
import '../screens/user/onboarding/onboarding_screen.dart';

// ─── Auth ───────────────────────────────────────────────────────────────────
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';

// ─── Dashboard ───────────────────────────────────────────────────────────────
import '../screens/user/dashboard/home_dashboard.dart';

// ─── Flight screens ──────────────────────────────────────────────────────────
import '../screens/user/flight/flight_search_page.dart';
import '../screens/user/flight/flight_results_page.dart';
import '../screens/user/flight/flight_detail_screen.dart';
import '../screens/user/flight/saved_flights_screen.dart';

// ─── Booking screens ─────────────────────────────────────────────────────────
import '../screens/user/booking/booking_detail_screen.dart';
import '../screens/user/booking/cancel_booking_screen.dart';
import '../screens/user/booking/my_bookings_screen.dart';
import '../screens/user/booking/passenger_details_screen.dart';
import '../screens/user/booking/refund_status_screen.dart';

// ─── Payment screens (NEW) ───────────────────────────────────────────────────
import '../screens/user/booking/payment_screen.dart';
import '../screens/user/booking/payment_success_screen.dart';

// ─── Seat & Add-On screens ────────────────────────────────────────────────────
import '../screens/user/booking/seat_selection_page.dart';
import '../screens/user/booking/addon_selection_page.dart';

// ─── Models (importing for FlightBooking type, in case you need it elsewhere) ──
import '../models/firebase_models.dart';

class AppRoutes {
  // ─── Route names ────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String passwordReset = '/password-reset';

  // Dashboard
  static const String homeDashboard = '/home-dashboard';
  static const String home = '/home'; // Alternative home route

  // Flight flow
  static const String flightSearch = '/flight-search';
  static const String flightResults = '/flight-results';
  static const String flightDetail = '/flight-detail';
  static const String savedFlights = '/saved-flights';

  // Booking flow
  static const String myBookings = '/my-bookings';
  static const String bookingDetail = '/booking-detail';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String bookingHistory = '/booking-history'; // Alternative route
  static const String cancelBooking = '/cancel-booking';
  static const String refundStatus = '/refund-status';

  // NEW sub-flows
  static const String seatSelection = '/seat-selection';
  static const String addonSelection = '/addon-selection';
  static const String passengerDetails = '/passenger-details';
  
  // ─── Payment routes (UPDATED) ─────────────────────────────────────────────
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';

  // Edit Profile placeholder
  static const String editProfile = '/edit-profile';

  // Enterprise / extra placeholders
  static const String notifications = '/notifications';
  static const String explore = '/explore';
  static const String deals = '/deals';
  static const String groupBooking = '/group-booking';
  static const String support = '/support';

  // ─── "Static" Route → WidgetBuilder Map ────────────────────────────────────
  // Use this map for screens that do NOT need constructor arguments.
  static Map<String, WidgetBuilder> get routes {
    return {
      // Core flows
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      passwordReset: (context) => const PasswordResetScreen(),

      // Dashboard
      homeDashboard: (context) => const HomeDashboard(userName: "John Doe"),
      home: (context) => const HomeDashboard(userName: "John Doe"), // Alternative

      // Flight flow
      flightSearch: (context) => const FlightSearchPage(),
      flightResults: (context) => const FlightResultsPage(),
      savedFlights: (context) => const SavedFlightsScreen(),

      // Booking flow (no-arg screens)
      myBookings: (context) => const MyBookingsScreen(),
      bookingHistory: (context) => const MyBookingsScreen(), // Alternative

      // NEW sub‐flows (no-arg placeholders)
      seatSelection: (context) => const SeatSelectionPage(),
      addonSelection: (context) => const AddonSelectionPage(),

      // NOTE: payment and paymentSuccess moved to onGenerateRoute since they need arguments

      // Edit Profile placeholder
      editProfile: (context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(
          child: Text(
            'EditProfileScreen has not been implemented yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),

      // Enterprise / extra placeholders
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

  // ─── onGenerateRoute ────────────────────────────────────────────────────────
  // Use this for screens that do require constructor arguments.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ─── Flight Detail (reads args via ModalRoute.of(context)) ─────────────
      case flightDetail: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => const FlightDetailScreen(),
            settings: settings,
          );
        }
        break;
      }

      // ─── Booking Detail (expects a String bookingId) ────────────────────────
      case bookingDetail: {
        final bookingId = settings.arguments as String?;
        if (bookingId != null) {
          return MaterialPageRoute(
            builder: (context) => BookingDetailScreen(bookingId: bookingId),
            settings: settings,
          );
        }
        break;
      }

      // ─── Booking Confirmation (expects a String bookingId) ──────────────────
      case bookingConfirmation: {
        final bookingId = settings.arguments as String?;
        if (bookingId != null) {
          // Uncomment once you create BookingConfirmationScreen:
          // return MaterialPageRoute(
          //   builder: (context) => BookingConfirmationScreen(bookingId: bookingId),
          //   settings: settings,
          // );
          
          // For now, redirect to payment success as alternative
          return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
            settings: settings,
          );
        }
        break;
      }

      // ─── Cancel Booking (expects a String bookingId) ────────────────────────
      case cancelBooking: {
        final bookingId = settings.arguments as String?;
        if (bookingId != null) {
          return MaterialPageRoute(
            builder: (context) => CancelBookingScreen(bookingId: bookingId),
            settings: settings,
          );
        }
        break;
      }

      // ─── Refund Status (expects a String bookingId) ─────────────────────────
      case refundStatus: {
        final bookingId = settings.arguments as String?;
        if (bookingId != null) {
          return MaterialPageRoute(
            builder: (context) => RefundStatusScreen(bookingId: bookingId),
            settings: settings,
          );
        }
        break;
      }

      // ─── Seat Selection (expects a Map<String, dynamic>) ────────────────────
      case seatSelection: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => const SeatSelectionPage(),
            settings: settings,
          );
        }
        break;
      }

      // ─── Add-On Selection (expects a Map<String, dynamic>) ──────────────────
      case addonSelection: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => const AddonSelectionPage(),
            settings: settings,
          );
        }
        break;
      }

      // ─── Passenger Details (no arguments needed in constructor) ─────────────
      case passengerDetails: {
        // Even if you passed a "bookingId"/"booking" in arguments,
        // PassengerDetailsScreen's constructor currently doesn't accept parameters.
        return MaterialPageRoute(
          builder: (context) => const PassengerDetailsScreen(),
          settings: settings,
        );
      }

      // ─── Payment Screen (expects Map<String, dynamic> arguments) ────────────
      case payment: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => const PaymentScreen(),
            settings: settings,
          );
        } else {
          // Handle case where no arguments provided
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Payment Error'),
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Payment Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No booking data found.\nPlease restart the booking process.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            settings: settings,
          );
        }
      }

      // ─── Payment Success Screen (expects Map<String, dynamic> arguments) ────
      case paymentSuccess: {
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
            settings: settings,
          );
        } else {
          // Handle case where no arguments provided
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Success'),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your booking has been confirmed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            settings: settings,
          );
        }
      }

      default:
        return null;
    }
    return null;
  }
}