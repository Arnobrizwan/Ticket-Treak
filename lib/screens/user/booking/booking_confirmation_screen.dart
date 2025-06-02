import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId; // Pass bookingId to fetch specific booking

  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  // Color palette from LoginScreen
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Booking data
  String _flight = '';
  String _dateTime = '';
  String _passengerFullName = '';
  String _passportNumber = '';
  String _nationality = '';
  String _contactEmail = '';
  String _contactPhone = '';
  Map<String, dynamic> _addOns = {'baggage': 0.0, 'meal': 0.0, 'insurance': 0.0};
  double _totalPaid = 0.0;
  String _bookingId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
  }

  // Fetch booking data from Firestore
  Future<void> _fetchBookingData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot booking = await _firestore
            .collection('bookings')
            .doc(widget.bookingId)
            .get();

        if (booking.exists) {
          var data = booking.data() as Map<String, dynamic>;
          var passenger = data['passengers'][0] ?? {};
          setState(() {
            _flight = '${data['flight']['code'] ?? 'AK123'} | ${data['flight']['route'] ?? 'KUL > BKK'}';
            _dateTime = '20 June 2025, 10:00 AM (GMT+8)'; // Hardcoded to match earlier UI; update if stored
            _passengerFullName = passenger['fullName'] ?? 'Arnob';
            _passportNumber = passenger['passportNumber'] ?? 'AI2345678';
            _nationality = passenger['nationality'] ?? 'Malaysia';
            _contactEmail = passenger['contactEmail'] ?? 'arnob@email.com';
            _contactPhone = passenger['contactPhone'] ?? '+60 123456789';
            _addOns = data['addons'] ?? {'baggage': 0.0, 'meal': 0.0, 'insurance': 0.0};
            _totalPaid = data['fareSummary']['total'] ?? 72.50;
            _bookingId = widget.bookingId;
            _isLoading = false;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking not found.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching booking data: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to view booking details.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Mock actions for buttons
  void _sendEmailReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email receipt sent!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sendSMSReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS receipt sent!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Navigate to home
  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.homeDashboard,
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Confirmation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Number $_bookingId',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AK123',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'KUL\nKuala Lumpur',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: darkGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '10:00 AM',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.flight_takeoff,
                                    size: 24,
                                    color: primaryColor,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'BKK',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Bangkok',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: darkGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '11:00 AM',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: _sendEmailReceipt,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryColor,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: primaryColor),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.email, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'Email Receipt',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _sendSMSReceipt,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: primaryColor,
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: primaryColor),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.sms, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'SMS Receipt',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Back to Home Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                          elevation: 2,
                        ),
                        child: Text(
                          'Back to Home',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}