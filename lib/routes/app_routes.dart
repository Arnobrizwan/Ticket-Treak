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
// import '../models/firebase_models.dart'; // Uncomment if FlightBooking or other models are needed here

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
      homeDashboard: (context) => const HomeDashboard(
          userName: "John Doe"), // Example: Pass necessary data
      home: (context) =>
          const HomeDashboard(userName: "John Doe"), // Alternative

      // Flight flow
      flightSearch: (context) => const FlightSearchPage(),
      // flightResults: (context) => const FlightResultsPage(), // Likely needs args, move to onGenerateRoute
      savedFlights: (context) => const SavedFlightsScreen(),

      // Booking flow (no-arg screens)
      myBookings: (context) => const MyBookingsScreen(),
      bookingHistory: (context) => const MyBookingsScreen(), // Alternative

      // NEW sub‐flows (no-arg placeholders, may need args)
      // seatSelection: (context) => const SeatSelectionPage(), // Likely needs args
      // addonSelection: (context) => const AddonSelectionPage(), // Likely needs args

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
    final args = settings.arguments; // Get arguments once

    switch (settings.name) {
      case flightResults:
        // Example: Assuming FlightResultsPage takes arguments
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (context) =>
                const FlightResultsPage(), // Pass args to constructor if needed
            settings: settings, // Pass settings to preserve arguments
          );
        }
        break;
      // ─── Flight Detail (reads args via ModalRoute.of(context)) ─────────────
      case flightDetail:
        {
          // FlightDetailScreen might read arguments itself using ModalRoute.of(context).settings.arguments
          // So, just ensure it's routed correctly.
          return MaterialPageRoute(
            builder: (context) => const FlightDetailScreen(),
            settings:
                settings, // Pass settings to allow ModalRoute.of(context) to access args
          );
        }

      // ─── Booking Detail (expects a Map with 'bookingId') ───────────────────
      case bookingDetail:
        {
          if (args is Map<String, dynamic> && args.containsKey('bookingId')) {
            final bookingId = args['bookingId'] as String?;
            if (bookingId != null) {
              return MaterialPageRoute(
                builder: (context) => BookingDetailScreen(bookingId: bookingId),
                settings: settings,
              );
            }
          }
          // Optional: Add an error route or default behavior if args are incorrect
          debugPrint(
              'Error: Incorrect arguments for bookingDetail route. Expected Map with "bookingId".');
          break;
        }

      // ─── Booking Confirmation (expects a Map with 'bookingId') ───────────────
      case bookingConfirmation:
        {
          if (args is Map<String, dynamic> && args.containsKey('bookingId')) {
            // final bookingId = args['bookingId'] as String;
            // Uncomment once you create BookingConfirmationScreen:
            // return MaterialPageRoute(
            //   builder: (context) => BookingConfirmationScreen(bookingId: bookingId),
            //   settings: settings,
            // );

            // For now, redirect to payment success as alternative, passing args along
            return MaterialPageRoute(
              builder: (context) =>
                  const PaymentSuccessScreen(), // PaymentSuccessScreen reads args itself
              settings: settings, // Pass settings along
            );
          }
          break;
        }

      // ─── Cancel Booking (expects a Map with 'bookingId') ────────────────────
      case cancelBooking:
        {
          if (args is Map<String, dynamic> && args.containsKey('bookingId')) {
            final bookingId = args['bookingId'] as String?;
            if (bookingId != null) {
              return MaterialPageRoute(
                builder: (context) => CancelBookingScreen(bookingId: bookingId),
                settings: settings,
              );
            }
          }
          break;
        }

      // ─── Refund Status (expects a Map with 'bookingId') ─────────────────────
      case refundStatus:
        {
          if (args is Map<String, dynamic> && args.containsKey('bookingId')) {
            final bookingId = args['bookingId'] as String?;
            if (bookingId != null) {
              return MaterialPageRoute(
                builder: (context) => RefundStatusScreen(bookingId: bookingId),
                settings: settings,
              );
            }
          }
          break;
        }

      // ─── Seat Selection (expects Map<String, dynamic> arguments) ────────────
      case seatSelection:
        {
          // SeatSelectionPage might read arguments itself using ModalRoute.of(context).settings.arguments
          return MaterialPageRoute(
            builder: (context) => const SeatSelectionPage(),
            settings: settings,
          );
        }

      // ─── Add-On Selection (expects Map<String, dynamic> arguments) ──────────
      case addonSelection:
        {
          // AddonSelectionPage might read arguments itself using ModalRoute.of(context).settings.arguments
          return MaterialPageRoute(
            builder: (context) => const AddonSelectionPage(),
            settings: settings,
          );
        }

      // ─── Passenger Details (reads arguments itself) ─────────────────────────
      case passengerDetails:
        {
          return MaterialPageRoute(
            builder: (context) => const PassengerDetailsScreen(),
            settings:
                settings, // Pass settings to allow ModalRoute.of(context) to access args
          );
        }

      // ─── Payment Screen (reads arguments itself) ────────────────────────────
      case payment:
        {
          return MaterialPageRoute(
            builder: (context) => const PaymentScreen(),
            settings:
                settings, // Pass settings to allow ModalRoute.of(context) to access args
          );
        }

      // ─── Payment Success Screen (reads arguments itself) ────────────────────
      case paymentSuccess:
        {
          return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
            settings:
                settings, // Pass settings to allow ModalRoute.of(context) to access args
          );
        }

      default:
        // If the route is not found in onGenerateRoute, it will fall back to the 'routes' map.
        // If not found there either, Flutter shows an error.
        // You can add a generic error page here if desired.
        debugPrint('Unhandled route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
    // Fallback if a case breaks without returning a route (should be avoided)
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(child: Text('Could not navigate to ${settings.name}')),
      ),
    );
  }
}
