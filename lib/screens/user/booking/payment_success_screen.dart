import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'package:ticket_trek/routes/app_routes.dart';
import 'package:intl/intl.dart'; // For date formatting if needed

// --- "Violin" color palette (consistent with other screens) ---
const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
const Color textColor = Color(0xFF35281E); // Deep Wood
const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
const Color accentColor = Color(0xFFD4A373); // Warm Highlight
const Color errorColor = Color(0xFFEF4444); // Red for errors
const Color successColor = Color(0xFF10B981); // Green for success

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data state
  String? _bookingDocumentId; // Firestore document ID
  String? _bookingReferenceDisplay; // User-facing booking ID like "TT123XYZ"
  double _totalAmountPaid = 0.0;
  String _currency = 'MYR';
  List<Map<String, dynamic>> _passengerList = [];
  Map<String, dynamic> _flightDetailsMap = {};
  DateTime? _bookingTimestamp;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // didChangeDependencies will be called after initState and handle argument fetching
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if data fetching has already been initiated to avoid multiple calls
    // _bookingDocumentId acts as a flag here. If it's null, means we haven't processed args yet.
    if (_bookingDocumentId == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['bookingId'] != null) {
        _bookingDocumentId = args['bookingId'] as String;
        // Set loading to true before fetching, in case it was set to false by a previous error state.
        if (mounted) {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
        }
        _fetchBookingDetails();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Booking ID not provided. Cannot load details.";
          });
        }
      }
    }
  }

  Future<void> _fetchBookingDetails() async {
    if (_bookingDocumentId == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error: Booking Document ID is missing.";
        });
      }
      return;
    }

    // Ensure we are in a loading state visually
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final docSnapshot =
          await _firestore.collection('bookings').doc(_bookingDocumentId).get();

      if (!mounted) return; // Check if the widget is still in the tree

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _bookingReferenceDisplay = data['bookingId']
              as String?; // User-facing booking ref from Firestore
          _totalAmountPaid = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
          _currency = data['currency'] as String? ?? 'MYR';

          final passengersData = data['passengers'] as List<dynamic>?;
          _passengerList = passengersData?.map((p) {
                if (p is Map<String, dynamic>) return p;
                return <String, dynamic>{}; // return empty map if cast fails
              }).toList() ??
              [];

          _flightDetailsMap =
              data['flightDetails'] as Map<String, dynamic>? ?? {};

          final timestamp = data['createdAt'] as Timestamp?;
          _bookingTimestamp = timestamp?.toDate();

          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Booking details not found. It might have been cancelled or does not exist.";
        });
      }
    } catch (e, s) {
      debugPrint("Error fetching booking details: $e");
      debugPrint("Stacktrace: $s");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Failed to load booking details. Please check your connection and try again.";
        });
      }
    }
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));

    // Start animations only after a slight delay or when data is ready
    // For now, let them start, loading indicator will cover UI
    _bounceController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _shareBookingDetails() {
    if (_isLoading || _errorMessage != null)
      return; // Don't share if data isn't loaded

    final departureDate = _flightDetailsMap['departureDate'] ?? 'N/A';
    final departureTime = _flightDetailsMap['departureTime'] ?? 'N/A';
    final fromRoute =
        _flightDetailsMap['fromCity'] ?? _flightDetailsMap['from'] ?? 'N/A';
    final toRoute =
        _flightDetailsMap['toCity'] ?? _flightDetailsMap['to'] ?? 'N/A';
    final fromCode = _flightDetailsMap['from'] ?? 'N/A';
    final toCode = _flightDetailsMap['to'] ?? 'N/A';

    final bookingText = '''
🎉 Booking Confirmed! - TicketTrek

Reference: ${_bookingReferenceDisplay ?? 'N/A'}
Route: $fromRoute ($fromCode) → $toRoute ($toCode)
Flight: ${_flightDetailsMap['flightNumber'] ?? 'N/A'}
Date: $departureDate at $departureTime
Passengers: ${_passengerList.length}
Total Paid: $_currency ${_totalAmountPaid.toStringAsFixed(2)}

Thank you for booking with TicketTrek!
''';
    Share.share(bookingText,
        subject:
            'Your Flight Booking Confirmation - ${_bookingReferenceDisplay ?? ""}');
  }

  void _copyBookingReference() {
    if (_bookingReferenceDisplay != null &&
        _bookingReferenceDisplay!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _bookingReferenceDisplay!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking reference copied!'),
            backgroundColor: successColor.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                (MediaQuery.of(context).padding.bottom +
                    80)), // Adjust margin to be above bottom nav
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10), // Adjusted padding
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildSuccessHeader(),
                              const SizedBox(height: 28),
                              _buildBookingConfirmation(),
                              const SizedBox(height: 20),
                              _buildFlightDetails(),
                              const SizedBox(height: 20),
                              _buildPassengerDetails(),
                              const SizedBox(height: 20),
                              _buildPaymentSummary(),
                              const SizedBox(height: 28),
                              _buildActionButtons(),
                              const SizedBox(
                                  height: 20), // Space before bottom bar
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: errorColor, size: 50),
            const SizedBox(height: 18),
            Text(
              'Oops! Something Went Wrong',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ??
                  "An unexpected error occurred. Please try again.",
              style: TextStyle(fontSize: 15, color: darkGrey.withOpacity(0.9)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                // Check if _fetchBookingDetails is callable and bookingDocumentId exists
                if (_bookingDocumentId != null) {
                  if (mounted) {
                    setState(() {
                      _isLoading =
                          true; // Set loading to true to show indicator
                      _errorMessage = null;
                    });
                  }
                  _fetchBookingDetails(); // Retry fetching
                } else {
                  // If no booking ID, perhaps navigate home or show a different error
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                  _bookingDocumentId != null ? 'Retry Loading' : 'Go to Home'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: successColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: successColor.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6)),
              ],
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 45),
          ),
          const SizedBox(height: 18),
          const Text(
            'Payment Successful!',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your flight booking is confirmed.',
            style: TextStyle(fontSize: 15, color: darkGrey.withOpacity(0.85)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingConfirmation() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.confirmation_number_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Booking Confirmation',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withOpacity(0.20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking Reference',
                            style: TextStyle(
                                fontSize: 12,
                                color: darkGrey,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _bookingReferenceDisplay ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 1.2,
                              fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  if (_bookingReferenceDisplay != null &&
                      _bookingReferenceDisplay!.isNotEmpty)
                    IconButton(
                      onPressed: _copyBookingReference,
                      icon: const Icon(Icons.copy_all_rounded,
                          color: primaryColor, size: 20),
                      tooltip: 'Copy reference',
                      splashRadius: 18,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'System ID',
                    _bookingDocumentId ?? 'N/A',
                    Icons.dns_rounded, // Changed Icon
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInfoItem(
                    'Status',
                    'Confirmed',
                    Icons.check_circle_outline_rounded, // Changed Icon
                    valueColor: successColor,
                  ),
                ),
              ],
            ),
            if (_bookingTimestamp != null) ...[
              const SizedBox(height: 10),
              _buildInfoItem(
                'Booked On',
                DateFormat('dd MMM yyyy, hh:mm a')
                    .format(_bookingTimestamp!), // Corrected DateFormat
                Icons.calendar_month_rounded,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFlightDetails() {
    final String from = _flightDetailsMap['from'] ?? 'N/A';
    final String to = _flightDetailsMap['to'] ?? 'N/A';
    final String fromCity = _flightDetailsMap['fromCity'] ?? from;
    final String toCity = _flightDetailsMap['toCity'] ?? to;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.flight_takeoff_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Flight Details',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(from,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      Text(fromCity,
                          style: TextStyle(fontSize: 12, color: darkGrey)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: primaryColor.withOpacity(0.8), size: 18),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(to,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      Text(toCity,
                          style: TextStyle(fontSize: 12, color: darkGrey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 2,
                    child: _buildFlightInfo(
                        'Date',
                        _flightDetailsMap['departureDate'] ?? 'N/A',
                        Icons.calendar_today_rounded)),
                Expanded(
                    flex: 2,
                    child: _buildFlightInfo(
                        'Time',
                        _flightDetailsMap['departureTime'] ?? 'N/A',
                        Icons.access_time_filled_rounded)),
                Expanded(
                    flex: 3,
                    child: _buildFlightInfo(
                        'Flight No.',
                        _flightDetailsMap['flightNumber'] ?? 'N/A',
                        Icons.airplane_ticket_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerDetails() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.people_alt_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text('Passengers (${_passengerList.length})',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ],
            ),
            const SizedBox(height: 14),
            if (_passengerList.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passengerList.length,
                itemBuilder: (context, index) {
                  final passenger = _passengerList[index];
                  // Ensure passenger is a Map<String, dynamic>
                  final String fullName =
                      (passenger is Map && passenger['fullName'] is String)
                          ? passenger['fullName']
                          : 'Passenger ${index + 1}';
                  final String passportNumber = (passenger is Map &&
                          passenger['passportNumber'] is String)
                      ? passenger['passportNumber']
                      : '';
                  final bool isPrimary = (passenger is Map &&
                          passenger['isPrimaryPassenger'] is bool)
                      ? passenger['isPrimaryPassenger']
                      : false;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        color: subtleGrey.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.8),
                          radius: 14,
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                              if (passportNumber.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text('Passport: $passportNumber',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: darkGrey.withOpacity(0.9))),
                                ),
                            ],
                          ),
                        ),
                        if (isPrimary)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('Primary',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No passenger details available.',
                    style: TextStyle(
                        color: darkGrey, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.credit_card_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Payment Summary',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: successColor.withOpacity(0.20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Paid',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor)),
                        Text('Payment successfully processed',
                            style: TextStyle(fontSize: 11, color: darkGrey)),
                      ],
                    ),
                  ),
                  Text(
                    '$_currency ${_totalAmountPaid.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: successColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading || _errorMessage != null
                    ? null
                    : _shareBookingDetails,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.home, (route) => false);
                },
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom:
              MediaQuery.of(context).padding.bottom + 12), // Adjusted padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ||
                      _errorMessage != null ||
                      _bookingDocumentId == null
                  ? null // Disable if loading, error, or no docId
                  : () {
                      Navigator.pushNamed(
                          context,
                          AppRoutes
                              .bookingDetail, // CORRECTED: Changed from bookingDetails to bookingDetail
                          arguments: {
                            'bookingId': _bookingDocumentId!
                          } // Safe to use ! due to check
                          );
                    },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('View Booking Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'A confirmation email has been sent to your registered email address.',
            style: TextStyle(fontSize: 11, color: darkGrey.withOpacity(0.85)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6), // Compacted padding
      decoration: BoxDecoration(
          color: subtleGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: darkGrey.withOpacity(0.9)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: darkGrey.withOpacity(0.9),
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFlightInfo(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: primaryColor.withOpacity(0.9), size: 16),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: darkGrey.withOpacity(0.9),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
