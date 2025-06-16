import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticket_trek/routes/app_routes.dart';
import 'package:intl/intl.dart';

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
  String? _bookingDocumentId;
  String? _bookingReferenceDisplay;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bookingDocumentId == null) {
      // Logic to get bookingId from arguments
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        // If coming from MyBookingsScreen
        _bookingDocumentId = args;
      } else if (args is Map<String, dynamic> &&
          args.containsKey('bookingId')) {
        // If coming from older flow
        _bookingDocumentId = args['bookingId'];
      }

      if (_bookingDocumentId != null) {
        _fetchBookingDetails();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Booking ID not provided.";
        });
      }
    }
  }

  Future<void> _fetchBookingDetails() async {
    if (_bookingDocumentId == null) {
      setState(() => _errorMessage = "Error: Booking Document ID is missing.");
      return;
    }
    setState(() => _isLoading = true);

    try {
      final docSnapshot =
          await _firestore.collection('bookings').doc(_bookingDocumentId).get();
      if (!mounted) return;
      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          _bookingReferenceDisplay =
              data['bookingReference'] as String? ?? 'N/A';
          _totalAmountPaid = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          _currency = data['currency'] as String? ?? 'MYR';
          _passengerList =
              List<Map<String, dynamic>>.from(data['passengers'] ?? []);
          _flightDetailsMap = data['flightDetails'] as Map<String, dynamic>? ??
              {}; // Placeholder
          _bookingTimestamp = (data['createdAt'] as Timestamp?)?.toDate();
          _isLoading = false;
        });
        // Start animations after data is loaded
        _bounceController.forward();
        _fadeController.forward();
        _slideController.forward();
      } else {
        setState(() => _errorMessage = "Booking details not found.");
      }
    } catch (e) {
      if (mounted)
        setState(() => _errorMessage = "Failed to load booking details.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _fadeController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _copyBookingReference() {
    if (_bookingReferenceDisplay != null &&
        _bookingReferenceDisplay!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _bookingReferenceDisplay!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Booking reference copied!'),
            backgroundColor: successColor.withOpacity(0.9),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.fromLTRB(
                20, 0, 20, (MediaQuery.of(context).padding.bottom + 80)),
            duration: const Duration(seconds: 2)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor))
            : _errorMessage != null
                ? _buildErrorState()
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildSuccessHeader(),
                              const SizedBox(height: 28),
                              _buildBookingConfirmation(),
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
    // ... Error UI remains the same
    return Center(child: Text(_errorMessage ?? "An unknown error occurred."));
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
                    offset: const Offset(0, 6))
              ],
            ),
            child:
                const Icon(Icons.check_rounded, color: Colors.white, size: 45),
          ),
          const SizedBox(height: 18),
          const Text('Payment Successful!',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Your flight booking is confirmed.',
              style: TextStyle(fontSize: 15, color: darkGrey.withOpacity(0.85)),
              textAlign: TextAlign.center),
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
                  offset: const Offset(0, 4))
            ]),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.confirmation_number_rounded,
                      color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('Booking Confirmation',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.20))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Booking Reference',
                            style: TextStyle(
                                fontSize: 12,
                                color: darkGrey,
                                fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(_bookingReferenceDisplay ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 1.2,
                                fontFamily: 'monospace')),
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
                        splashRadius: 18),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _buildInfoItem(
                        'Total Paid',
                        '$_currency ${_totalAmountPaid.toStringAsFixed(2)}',
                        Icons.credit_card,
                        valueColor: successColor)),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildInfoItem('Passengers',
                        '${_passengerList.length}', Icons.people_alt_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -2))
      ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              // THIS IS THE FIX: Changed argument from Map to String
              onPressed: _isLoading ||
                      _errorMessage != null ||
                      _bookingDocumentId == null
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.bookingDetail,
                        arguments: _bookingDocumentId!, // Now passes a String
                      );
                    },
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('View Booking Details'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.homeDashboard, (route) => false),
              icon: const Icon(Icons.home_outlined, size: 20),
              label: const Text("Back to Home"),
              style: TextButton.styleFrom(foregroundColor: darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: darkGrey.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: darkGrey.withOpacity(0.9),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: valueColor ?? textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ],
    );
  }
}
