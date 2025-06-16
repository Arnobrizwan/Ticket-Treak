import 'package:flutter/material.dart';

// Import all your screen files here...
import '../screens/user/splash/splash_screen.dart';
import '../screens/user/onboarding/onboarding_screen.dart';
import '../screens/user/auth/login_screen.dart';
import '../screens/user/auth/register_screen.dart';
import '../screens/user/auth/password_reset_screen.dart';
import '../screens/user/dashboard/home_dashboard.dart';
import '../screens/user/flight/flight_search_page.dart';
import '../screens/user/flight/flight_results_page.dart';
import '../screens/user/flight/flight_detail_screen.dart';
import '../screens/user/flight/saved_flights_screen.dart';
import '../screens/user/booking/booking_detail_screen.dart';
import '../screens/user/booking/my_bookings_screen.dart';
import '../screens/user/booking/passenger_details_screen.dart';
import '../screens/user/booking/payment_screen.dart';
import '../screens/user/booking/payment_success_screen.dart';
import '../screens/user/booking/seat_selection_page.dart';
import '../screens/user/booking/addon_selection_page.dart';




import '../screens/flight_management_screen.dart'; 
import '../screens/booking_management_screen.dart'; 
import '../screens/refund_requests_screen.dart'; 
import '../screens/user_management_screen.dart';
import '../screens/settings_screen.dart'; 
import '../screens/user_management_screen.dart';
import '../screens/admin_analytics_screen.dart';




class AppRoutes {
  // --- Route names ---
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String passwordReset = '/password-reset';
  static const String homeDashboard = '/home-dashboard';
  static const String home = '/home';
  static const String flightSearch = '/flight-search';
  static const String flightResults = '/flight-results';
  static const String flightDetail = '/flight-detail';
  static const String savedFlights = '/saved-flights';
  static const String myBookings = '/my-bookings';
  static const String bookingDetail = '/booking-detail';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String bookingHistory = '/booking-history';
  static const String seatSelection = '/seat-selection';
  static const String addonSelection = '/addon-selection';
  static const String passengerDetails = '/passenger-details';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String editProfile = '/edit-profile';
  static const String notifications = '/notifications';
  static const String explore = '/explore';
  static const String deals = '/deals';
  static const String groupBooking = '/group-booking';
  static const String support = '/support';





// Admin Routes
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String flightManagement = '/flight-management';
  static const String bookingManagement = '/booking-management';
  static const String refundRequests = '/refund-requests';
  static const String userManagement = '/user-management';
  static const String settings = '/settings';
  static const String userManagement = '/user-management';
  static const String adminAnalytics = '/admin-analytics';


  // --- Routes without arguments ---
  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => const SplashScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      passwordReset: (context) => const PasswordResetScreen(),
      homeDashboard: (context) => const HomeDashboard(userName: "John Doe"),
      home: (context) => const HomeDashboard(userName: "John Doe"),
      flightSearch: (context) => const FlightSearchPage(),
      savedFlights: (context) => const SavedFlightsScreen(),
      myBookings: (context) => const MyBookingsScreen(),
      bookingHistory: (context) => const MyBookingsScreen(),



      // Admin Routes
        adminLogin: (context) => const AdminLoginScreen(),
        adminDashboard: (context) => const AdminDashboardScreen(), 
        flightManagement: (context) => const FlightManagementScreen(), 
        bookingManagement: (context) => const BookingManagementScreen(), 
        refundRequests: (context) => const RefundRequestsScreen(), 
        userManagement: (context) => const UserManagementScreen(), 
        adminAnalytics: (context) => const AdminAnalyticsScreen(),
        settings: (context) => const SettingsScreen(), 
      };





      
      // Placeholder screens...
      editProfile: (context) => Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: const Center(child: Text('Not Implemented'))),
      notifications: (context) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: const Center(child: Text('Not Implemented'))),
      explore: (context) => Scaffold(
          appBar: AppBar(title: const Text('Explore')),
          body: const Center(child: Text('Not Implemented'))),
      deals: (context) => Scaffold(
          appBar: AppBar(title: const Text('Deals')),
          body: const Center(child: Text('Not Implemented'))),
      groupBooking: (context) => Scaffold(
          appBar: AppBar(title: const Text('Group Booking')),
          body: const Center(child: Text('Not Implemented'))),
      support: (context) => Scaffold(
          appBar: AppBar(title: const Text('Support Chat')),
          body: const Center(child: Text('Not Implemented'))),
    };
  }

  // --- Routes that require arguments ---
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case bookingDetail:
        {
          String? bookingId;
          if (args is String) {
            bookingId = args;
          } else if (args is Map<String, dynamic> &&
              args.containsKey('bookingId')) {
            bookingId = args['bookingId'] as String?;
          }

          if (bookingId != null) {
            return MaterialPageRoute(
              // THIS IS THE FIX: The "!" tells the compiler bookingId is not null here.
              builder: (context) => BookingDetailScreen(bookingId: bookingId!),
              settings: settings,
            );
          }
          debugPrint(
              'Error: Incorrect arguments for bookingDetail. Expected a String or a Map containing "bookingId".');
          break;
        }

      case flightResults:
        return MaterialPageRoute(
            builder: (context) => const FlightResultsPage(),
            settings: settings);

      case flightDetail:
        return MaterialPageRoute(
            builder: (context) => const FlightDetailScreen(),
            settings: settings);

      case bookingConfirmation:
        return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
            settings: settings);

      case seatSelection:
        return MaterialPageRoute(
            builder: (context) => const SeatSelectionPage(),
            settings: settings);

      case addonSelection:
        return MaterialPageRoute(
            builder: (context) => const AddonSelectionPage(),
            settings: settings);

      case passengerDetails:
        return MaterialPageRoute(
            builder: (context) => const PassengerDetailsScreen(),
            settings: settings);

      case payment:
        return MaterialPageRoute(
            builder: (context) => const PaymentScreen(), settings: settings);

      case paymentSuccess:
        return MaterialPageRoute(
            builder: (context) => const PaymentSuccessScreen(),
            settings: settings);

      default:
        return _errorRoute(settings.name);
    }
    return _errorRoute(settings.name);
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
            child: Text(
                'Could not navigate to ${routeName ?? 'an unknown route'}.')),
      ),
    );
  }
}
