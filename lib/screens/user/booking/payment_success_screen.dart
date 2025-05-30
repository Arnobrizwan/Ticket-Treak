import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  // Color palette from LoginScreen
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _flight = 'AK123 | KUL > BKK';
  String _dateTime = '20 June 2025, 10:00 AM (GMT+8)';
  String _passenger = 'Arnob Rizwan\n12A - Window';
  double _totalPaid = 72.50;
  String _bookingId = 'AK123-58TX';

  @override
  void initState() {
    super.initState();
    _fetchBookingData();
  }

  // Fetch the latest booking data from Firestore
  Future<void> _fetchBookingData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot bookings = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (bookings.docs.isNotEmpty) {
          var data = bookings.docs.first.data() as Map<String, dynamic>;
          setState(() {
            _flight = data['flight']['code'] + ' | ' + data['flight']['route'];
            _totalPaid = data['fareSummary']['total'];
            _bookingId = data['bookingId'] ?? _bookingId; // Assuming bookingId is set earlier
            // Passenger data would need to be fetched from 'passengers' array if implemented
          });
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
      }
    }
  }

  // Mock actions for buttons
  void _confirmBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking confirmed!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _sendEmailConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email confirmation sent!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _viewMyBookings() {
    Navigator.pushNamed(context, AppRoutes.viewBookings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Success Checkmark
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your flight booking has been confirmed.',
                style: TextStyle(
                  fontSize: 16,
                  color: darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Booking Details Card
              Container(
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
                      _flight,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dateTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _passenger,
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
                        Text(
                          'Total Paid',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '\$${_totalPaid.toStringAsFixed(2)} USD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Booking ID',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          _bookingId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: primaryColor),
                      ),
                    ),
                    child: Text(
                      'Confirm Booking',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _sendEmailConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: primaryColor),
                      ),
                    ),
                    child: Text(
                      'Email Confirmation',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // View My Bookings Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _viewMyBookings,
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
                    'View My Bookings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Additional Info
              Text(
                "You'll also receive an email with your ticket and itinerary.",
                style: TextStyle(
                  fontSize: 14,
                  color: darkGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}