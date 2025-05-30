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
  static const String payment = '/payment';
  static const String passengerDetails = '/passenger-details';
  static const String paymentSuccess = '/payment-success';
  static const String viewBookings = '/view-bookings';
  static const String homeDashboard = '/home-dashboard';
  static const String bookingConfirmation = '/booking-confirmation';
  static const String cancelBooking = '/cancel-booking';
  static const String refundStatus = '/refund-status';
  static const String bookingDetail = '/booking-detail';


  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    passwordReset: (context) => const PasswordResetScreen(),
    dashboard: (context) => const HomeDashboard(userName: "John Doe"),
    searchFlight: (context) => const FlightSearchPage(),
    myBookings: (context) => const MyBookingsScreen(),
    bookingDetail: (context) => BookingDetailScreen(
      bookingId: ModalRoute.of(context)!.settings.arguments as String,
    ),
    bookingConfirmation: (context) => const Scaffold(body: Center(child: Text('Booking Confirmation Screen'))),
    cancelBooking: (context) => CancelBookingScreen(
      bookingId: ModalRoute.of(context)!.settings.arguments as String,
    ),
    refundStatus: (context) => RefundStatusScreen(
      bookingId: ModalRoute.of(context)!.settings.arguments as String,
    ),
            
  };
}