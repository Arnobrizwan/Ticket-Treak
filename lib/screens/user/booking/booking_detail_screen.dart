import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/routes/app_routes.dart'; // For navigation
// import 'package:path_provider/path_provider.dart'; // For PDF generation (optional)
// import 'package:pdf/widgets.dart' as pw; // For PDF generation (optional)
// import 'package:pdf/pdf.dart'; // For PDF page format and colors (optional)
// import 'dart:io'; // For File operations (optional)
// import 'package:share_plus/share_plus.dart'; // For sharing ticket (optional, if sharing files)

// --- Color Palette (consistent with other screens) ---
const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
const Color textColor = Color(0xFF35281E); // Deep Wood
const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
const Color accentColor = Color(0xFFD4A373); // Warm Highlight
const Color errorColor = Color(0xFFEF4444); // Red for errors
const Color successColor = Color(0xFF10B981); // Green for success
const Color ticketBackgroundColor =
    Color(0xFFFFFBF2); // Lighter Ivory for ticket

class BookingDetailScreen extends StatefulWidget {
  final String bookingId; // Firestore document ID

  const BookingDetailScreen({Key? key, required this.bookingId})
      : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _bookingDataFromFirestore;
  bool _isLoading = true;
  String? _errorMessage;

  // Extracted and structured details for easier UI access
  String? _displayBookingReference;
  String? _bookingStatus;
  DateTime? _bookingCreationDate;

  // Flight related
  String _originCode = 'N/A';
  String _destinationCode = 'N/A';
  String _originCity = 'N/A';
  String _destinationCity = 'N/A';
  String _departureDateStr = 'N/A';
  String _departureTimeStr = 'N/A';
  String _flightNumber = 'N/A';
  String _airlineName = 'Batik Airlines'; // Default airline if not found

  List<Map<String, dynamic>> _passengers = [];

  Map<String, dynamic> _seatBookingDetails = {};
  List<dynamic> _selectedAddons = [];

  double _totalPrice = 0.0;
  String _currency = 'MYR';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // For SMS dialog
  String? _userEmailForReceipt;
  String? _userPhoneForReceipt; // To store user's primary phone

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final docSnapshot =
          await _firestore.collection('bookings').doc(widget.bookingId).get();
      debugPrint(
          "Fetched booking document for ID (${widget.bookingId}): ${docSnapshot.exists ? docSnapshot.data() : 'Does not exist'}");

      if (!mounted) return;

      if (docSnapshot.exists) {
        _bookingDataFromFirestore = docSnapshot.data();
        _parseBookingData();
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Booking not found. It might have been cancelled or the ID is incorrect.";
        });
      }
    } catch (e, s) {
      debugPrint("Error fetching booking details: $e\nStacktrace: $s");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Failed to load booking details. Please check your connection.";
        });
      }
    }
  }

  void _parseBookingData() {
    if (_bookingDataFromFirestore == null) {
      debugPrint(
          "_parseBookingData: _bookingDataFromFirestore is null. Cannot parse.");
      return;
    }
    final data = _bookingDataFromFirestore!;
    debugPrint("_parseBookingData: Starting parsing for booking data: $data");

    _displayBookingReference =
        data['bookingReference'] as String? ?? data['bookingId'] as String?;
    _bookingStatus = data['status'] as String? ?? 'Unknown';

    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    _bookingCreationDate = createdAtTimestamp?.toDate();

    // --- Enhanced Flight Details Parsing ---
    _originCode = data['originCode'] as String? ?? 'N/A';
    _destinationCode = data['destinationCode'] as String? ?? 'N/A';

    final flightOfferMap = data['flightOffer'] as Map<String, dynamic>? ?? {};
    debugPrint("_parseBookingData: flightOfferMap: $flightOfferMap");

    _originCity = flightOfferMap['originCityName'] as String? ?? _originCode;
    _destinationCity =
        flightOfferMap['destinationCityName'] as String? ?? _destinationCode;

    final departureTimestamp = data['departureDate'] as Timestamp?;
    if (departureTimestamp != null) {
      _departureDateStr =
          DateFormat('yyyy-MM-dd').format(departureTimestamp.toDate());
      _departureTimeStr =
          DateFormat('hh:mm a').format(departureTimestamp.toDate());
      debugPrint(
          "_parseBookingData: Parsed top-level departureDate: $_departureDateStr, $_departureTimeStr");
    } else {
      _departureDateStr = 'N/A';
      _departureTimeStr = 'N/A';
      debugPrint(
          "_parseBookingData: Top-level departureDate Timestamp is null.");
    }

    String? tempFlightNumber;
    String? tempAirlineCode;
    String? parsedAirlineName;

    if (flightOfferMap.isNotEmpty) {
      final itineraries = flightOfferMap['itineraries'] as List<dynamic>?;
      if (itineraries != null && itineraries.isNotEmpty) {
        final firstItinerary = itineraries.first as Map<String, dynamic>?;
        if (firstItinerary != null) {
          final segments = firstItinerary['segments'] as List<dynamic>?;
          if (segments != null && segments.isNotEmpty) {
            final firstSegment = segments.first as Map<String, dynamic>?;
            if (firstSegment != null) {
              tempFlightNumber = firstSegment['number'] as String? ??
                  firstSegment['flightNumber'] as String?;
              tempAirlineCode = firstSegment['carrierCode'] as String?;
              parsedAirlineName = firstSegment['airlineName'] as String?;

              final segmentDeparture =
                  firstSegment['departure'] as Map<String, dynamic>?;
              if (segmentDeparture != null &&
                  segmentDeparture['at'] is String) {
                try {
                  final segmentDateTime =
                      DateTime.parse(segmentDeparture['at'] as String);
                  if (departureTimestamp != null &&
                      departureTimestamp.toDate().hour == 0 &&
                      departureTimestamp.toDate().minute == 0) {
                    _departureTimeStr =
                        DateFormat('hh:mm a').format(segmentDateTime);
                    debugPrint(
                        "_parseBookingData: Updated departureTimeStr from segment: $_departureTimeStr");
                  }
                  _departureDateStr =
                      DateFormat('yyyy-MM-dd').format(segmentDateTime);
                  debugPrint(
                      "_parseBookingData: Updated departureDateStr from segment: $_departureDateStr");
                } catch (e) {
                  debugPrint(
                      "Error parsing segment departure 'at' string: ${segmentDeparture['at']}. Error: $e");
                }
              }
            }
          }
        }
      }
      tempFlightNumber ??= flightOfferMap['flightNumber'] as String?;
      tempAirlineCode ??=
          (flightOfferMap['validatingAirlineCodes'] as List<dynamic>?)?.first
                  as String? ??
              flightOfferMap['carrierCode'] as String?;
      parsedAirlineName ??= flightOfferMap['airlineName'] as String?;
    }

    _flightNumber = tempFlightNumber ?? 'N/A';
    // Use parsedAirlineName if available, then tempAirlineCode, then default to "Batik Airlines"
    _airlineName = parsedAirlineName ?? (tempAirlineCode ?? 'Batik Airlines');
    if (_airlineName.isEmpty)
      _airlineName = 'Batik Airlines'; // Ensure it's not empty string

    debugPrint(
        "_parseBookingData: Final FlightNumber: $_flightNumber, Airline: $_airlineName");
    // --- End of Enhanced Flight Details Parsing ---

    final passengersData = data['passengers'] as List<dynamic>?;
    _passengers = passengersData?.map((p) {
          if (p is Map<String, dynamic>) return p;
          return <String, dynamic>{};
        }).toList() ??
        [];

    if (_passengers.isNotEmpty) {
      final primaryPassenger = _passengers.firstWhere(
          (p) => p['isPrimaryPassenger'] == true,
          orElse: () => _passengers.first);
      _userEmailForReceipt = primaryPassenger['contactEmail'] as String?;
      _userPhoneForReceipt =
          primaryPassenger['contactPhone'] as String?; // Get phone for SMS
    }
    _userEmailForReceipt ??= data['userEmail'] as String?;
    _userPhoneForReceipt ??= data['userPhone'] as String?; // Fallback for phone

    _seatBookingDetails = data['seatBooking'] as Map<String, dynamic>? ?? {};
    final addonBookingMap = data['addonBooking'] as Map<String, dynamic>? ?? {};
    _selectedAddons = addonBookingMap['selectedAddons'] as List<dynamic>? ?? [];

    _totalPrice = (data['totalAmount'] as num?)?.toDouble() ??
        (data['flightPrice'] as num?)?.toDouble() ??
        0.0;
    _currency = data['currency'] as String? ?? 'MYR';
    debugPrint("_parseBookingData: Parsing complete.");
  }

  void _sendReceipt(String method, {String? contactInfo}) {
    String message;
    if (method == "Email") {
      message = contactInfo != null && contactInfo.isNotEmpty
          ? 'Email receipt is being sent to $contactInfo.'
          : 'Email address not provided for receipt.';
      // TODO: Implement actual email sending logic here
    } else if (method == "SMS") {
      message = contactInfo != null && contactInfo.isNotEmpty
          ? 'SMS receipt is being sent to $contactInfo.'
          : 'Phone number not provided for SMS receipt.';
      // TODO: Implement actual SMS sending logic here
    } else {
      message = '$method receipt functionality is not yet implemented.';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: accentColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _showEmailReceiptDialog() async {
    _emailController.text = _userEmailForReceipt ?? '';
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.email_outlined, color: primaryColor),
              SizedBox(width: 10),
              Text('Send Email Receipt',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Enter the email address to send the booking receipt to:',
                      style: TextStyle(color: darkGrey)),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: primaryColor),
                      prefixIcon:
                          Icon(Icons.alternate_email_rounded, color: darkGrey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email address.';
                      }
                      if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value)) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style:
                      TextStyle(color: darkGrey, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.send_rounded, size: 18),
              label: Text('Send Receipt'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _sendReceipt("Email", contactInfo: _emailController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSmsReceiptDialog() async {
    _phoneController.text = _userPhoneForReceipt ?? '';
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.sms_outlined, color: primaryColor),
              SizedBox(width: 10),
              Text('Send SMS Receipt',
                  style:
                      TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  Text(
                      'Enter the phone number to send the booking receipt to (with country code):',
                      style: TextStyle(color: darkGrey)),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+1234567890',
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: primaryColor),
                      prefixIcon:
                          Icon(Icons.phone_android_rounded, color: darkGrey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number.';
                      }
                      if (!RegExp(r"^\+?[0-9\s-]{8,15}$").hasMatch(value)) {
                        // Basic validation
                        return 'Please enter a valid phone number.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style:
                      TextStyle(color: darkGrey, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.send_rounded, size: 18),
              label: Text('Send Receipt'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _sendReceipt("SMS", contactInfo: _phoneController.text);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadTicket() async {
    // PDF Generation and sharing code commented out as per request
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Ticket download (PDF) functionality is not yet implemented.'),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Booking Details',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : _bookingDataFromFirestore == null
                  ? _buildErrorState(
                      customMessage: "Booking data could not be loaded.")
                  : _buildContent(),
      bottomNavigationBar:
          _isLoading || _errorMessage != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildErrorState({String? customMessage}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: errorColor, size: 60),
            const SizedBox(height: 20),
            Text('Oops!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 10),
            Text(
              customMessage ?? _errorMessage ?? "An unexpected error occurred.",
              style: TextStyle(fontSize: 16, color: darkGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _fetchBookingDetails,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry Loading'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingHeader(),
          const SizedBox(height: 20),
          _buildTicketPreview(),
          const SizedBox(height: 24),
          _buildSectionTitle("Flight Itinerary", Icons.flight_takeoff_rounded),
          _buildFlightDetailsCard(),
          const SizedBox(height: 24),
          if (_seatBookingDetails.isNotEmpty || _selectedAddons.isNotEmpty) ...[
            _buildSectionTitle(
                "Services & Add-ons", Icons.room_service_rounded),
            if (_seatBookingDetails.isNotEmpty) _buildSeatDetailsCard(),
            if (_selectedAddons.isNotEmpty) _buildAddonsCard(),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle("Passenger Information", Icons.people_alt_rounded),
          _buildPassengersCard(),
          const SizedBox(height: 24),
          _buildSectionTitle("Payment Summary", Icons.credit_card_rounded),
          _buildPaymentCard(),
          const SizedBox(height: 24),
          _buildReceiptOptions(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBookingHeader() {
    String statusText = _bookingStatus ?? 'Unknown';
    Color statusColor = darkGrey;
    IconData statusIcon = Icons.hourglass_empty_rounded;

    switch (statusText.toLowerCase()) {
      case 'confirmed':
      case 'payment_successful':
      case 'pending_payment':
      case 'addons selected':
        statusColor = successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        statusColor = errorColor;
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = darkGrey;
        statusIcon = Icons.info_outline_rounded;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Reference',
              style: TextStyle(
                  fontSize: 14, color: darkGrey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            SelectableText(
              _displayBookingReference ?? 'N/A',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Status: ${statusText.replaceAll("_", " ").toUpperCase()}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ],
            ),
            if (_bookingCreationDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: darkGrey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Booked on: ${DateFormat('dd MMM yy, hh:mm a').format(_bookingCreationDate!)}',
                    style: TextStyle(fontSize: 13, color: darkGrey),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.95),
              primaryColor.withOpacity(0.85)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: ticketBackgroundColor,
              borderRadius: BorderRadius.circular(10.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _airlineName.toUpperCase(),
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1),
                    ),
                    Icon(Icons.flight_class_rounded,
                        color: primaryColor, size: 28),
                  ],
                ),
                Text(
                  'BOARDING PASS',
                  style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2.5),
                ),
                Divider(
                    color: primaryColor.withOpacity(0.3),
                    height: 20,
                    thickness: 0.8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ticketInfoColumn('FROM', _originCity, _originCode,
                        CrossAxisAlignment.start),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.arrow_right_alt_rounded,
                          color: primaryColor, size: 28),
                    ),
                    _ticketInfoColumn('TO', _destinationCity, _destinationCode,
                        CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ticketInfoColumn(
                        'FLIGHT', _flightNumber, '', CrossAxisAlignment.start),
                    _ticketInfoColumn('DATE', _departureDateStr, '',
                        CrossAxisAlignment.center),
                    _ticketInfoColumn(
                        'PASSENGERS',
                        _passengers.length.toString(),
                        '',
                        CrossAxisAlignment.end),
                  ],
                ),
                if (_passengers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _ticketInfoColumn(
                      'PASSENGER',
                      _passengers[0]['fullName'] ?? 'N/A',
                      '',
                      CrossAxisAlignment.start),
                ],
                const SizedBox(height: 12),
                Center(
                  child: Icon(Icons.qr_code_scanner_rounded,
                      size: 48, color: primaryColor.withOpacity(0.75)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticketInfoColumn(String label, String value, String subValue,
      CrossAxisAlignment alignment) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 10,
              color: darkGrey,
              fontWeight: FontWeight.w500,
              letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        if (subValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              subValue,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: darkGrey),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, bottom: 10.0),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFlightDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _detailRow('Origin:', '$_originCity ($_originCode)'),
            _detailRow('Destination:', '$_destinationCity ($_destinationCode)'),
            _detailRow('Departure Date:', _departureDateStr),
            _detailRow('Departure Time:', _departureTimeStr),
            _detailRow('Flight Number:', _flightNumber),
            _detailRow('Airline:', _airlineName),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatDetailsCard() {
    String seatsDisplay = "Not specified";
    if (_seatBookingDetails['selectedSeats'] is List &&
        (_seatBookingDetails['selectedSeats'] as List).isNotEmpty) {
      seatsDisplay = (_seatBookingDetails['selectedSeats'] as List).join(", ");
    } else if (_seatBookingDetails['seats'] is String &&
        (_seatBookingDetails['seats'] as String).isNotEmpty) {
      seatsDisplay = _seatBookingDetails['seats'];
    } else if (_passengers.isNotEmpty &&
        _passengers.any((p) =>
            p['seat'] != null &&
            (p['seat'] is String && (p['seat'] as String).isNotEmpty))) {
      seatsDisplay = _passengers
          .map((p) => p['seat'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .join(", ");
      if (seatsDisplay.isEmpty) seatsDisplay = "Not specified";
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seat Information",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            Divider(height: 16, color: subtleGrey),
            _detailRow('Aircraft Type:',
                _seatBookingDetails['aircraftType'] as String? ?? 'N/A'),
            _detailRow('Selected Seats:', seatsDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildAddonsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Selected Add-ons",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
            Divider(height: 16, color: subtleGrey),
            _selectedAddons.isEmpty
                ? Text("No add-ons selected.",
                    style: TextStyle(color: darkGrey))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _selectedAddons.map((addon) {
                      String addonName = "Unknown Add-on";
                      String addonDetails = "";
                      if (addon is Map<String, dynamic>) {
                        addonName = addon['name'] as String? ??
                            addon['type'] as String? ??
                            'Add-on';
                        addonDetails =
                            "(${addon['quantity'] ?? 1}x ${addon['price'] != null ? '$_currency ${(addon['price'] as num).toStringAsFixed(2)}' : ''})";
                      } else if (addon is String) {
                        addonName = addon;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Text("• $addonName $addonDetails".trim(),
                            style: TextStyle(fontSize: 14, color: textColor)),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _passengers.isEmpty
            ? Text("No passenger information available.",
                style: TextStyle(color: darkGrey))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passengers.length,
                itemBuilder: (context, index) {
                  final passenger = _passengers[index];
                  final String fullName =
                      passenger['fullName'] as String? ?? 'N/A';
                  final String passport =
                      passenger['passportNumber'] as String? ?? 'N/A';
                  final bool isPrimary =
                      passenger['isPrimaryPassenger'] == true;
                  final String passengerSeat =
                      passenger['seat'] as String? ?? 'N/A';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.8),
                          radius: 16,
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                      fontSize: 15)),
                              if (passport != 'N/A')
                                Text('Passport: $passport',
                                    style: TextStyle(
                                        fontSize: 13, color: darkGrey)),
                              if (passengerSeat != 'N/A')
                                Text('Seat: $passengerSeat',
                                    style: TextStyle(
                                        fontSize: 13, color: darkGrey)),
                            ],
                          ),
                        ),
                        if (isPrimary)
                          Chip(
                            label: Text('Primary',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold)),
                            backgroundColor: primaryColor.withOpacity(0.1),
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 0),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    Divider(color: subtleGrey.withOpacity(0.5)),
              ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _detailRow('Total Amount Paid:',
                '$_currency ${_totalPrice.toStringAsFixed(2)}',
                isHighlighted: true, valueFontSize: 16),
            _detailRow(
                'Payment Method:',
                _bookingDataFromFirestore?['paymentMethod'] as String? ??
                    'Card',
                icon: Icons.credit_card_rounded),
            _detailRow('Transaction ID:',
                _bookingDataFromFirestore?['transactionId'] as String? ?? 'N/A',
                icon: Icons.receipt_long_rounded),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value,
      {bool isHighlighted = false, IconData? icon, double? valueFontSize}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: darkGrey),
            const SizedBox(width: 10)
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                  color: darkGrey, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: isHighlighted ? primaryColor : textColor,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: valueFontSize ?? 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(
            "Actions & Receipts", Icons.settings_applications_rounded),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: Icon(Icons.download_for_offline_rounded, size: 20),
          label: Text('Download Ticket (PDF)'),
          onPressed: _downloadTicket,
          style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.email_outlined, size: 18),
                label: Text('Email Receipt'),
                onPressed: _showEmailReceiptDialog,
                style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.sms_outlined, size: 18),
                label: Text('SMS Receipt'),
                onPressed: _showSmsReceiptDialog, // Call the new SMS dialog
                style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, -3))
          ],
          border:
              Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: Icon(Icons.list_alt_rounded, size: 18),
              label: Text('My Bookings'),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.myBookings,
                    ModalRoute.withName(AppRoutes.home));
              },
              style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.7)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.home_rounded, size: 18),
              label: Text('Go Home'),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (route) => false);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
      ),
    );
  }
}
