// lib/screens/user/booking/payment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ticket_trek/routes/app_routes.dart';
import 'package:ticket_trek/services/stripe_service.dart';

/// ─── "Violin" color palette (same as before) ──────────────────────
const Color backgroundColor = Color(0xFFF5F0E1);
const Color primaryColor = Color(0xFF5C2E00);
const Color secondaryColor = Color(0xFF8B5000);
const Color textColor = Color(0xFF35281E);
const Color subtleGrey = Color(0xFFDAC1A7);
const Color darkGrey = Color(0xFF7E5E3C);
const Color accentColor = Color(0xFFD4A373);
const Color errorColor = Color(0xFFEF4444);
const Color successColor = Color(0xFF10B981);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Form controllers for billing details
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Focus nodes
  final FocusNode _cardHolderFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _postalCodeFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Form and state management
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  String? _errorMessage;

  // Stripe-specific
  final CardFormEditController _cardController = CardFormEditController();
  String? _paymentIntentClientSecret;

  // Booking data from previous screen
  Map<String, dynamic>? _bookingData;
  List<Map<String, dynamic>>? _passengers;
  String? _bookingId;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingData = args;
      _passengers = args['passengers'] as List<Map<String, dynamic>>?;
      _bookingId = args['bookingId'] as String?;
      _calculateTotalAmount();
      _createPaymentIntent();
    }
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _loadUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final userData = doc.data()!;
          _emailController.text = userData['email'] ?? user.email ?? '';
          _cardHolderController.text = userData['fullName'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }

  void _calculateTotalAmount() {
    if (_bookingData != null) {
      final adults = _bookingData!['adults'] as int? ?? 0;
      final children = _bookingData!['children'] as int? ?? 0;
      final basePrice = _bookingData!['price'] as double? ?? 299.0;

      _totalAmount = (adults * basePrice) + (children * basePrice * 0.7);
      _totalAmount += (_totalAmount * 0.12); // 12% tax
      _totalAmount += 25.0; // Service fee
    }
  }

  Future<void> _createPaymentIntent() async {
    try {
      final amountInCents = StripeService.amountToCents(_totalAmount);
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: amountInCents,
        currency: 'myr', // Malaysian Ringgit
        metadata: {
          'bookingId': _bookingId ?? '',
          'userId': _auth.currentUser?.uid ?? '',
          'passengerCount': _passengers?.length.toString() ?? '1',
        },
      );

      setState(() {
        _paymentIntentClientSecret = paymentIntent['client_secret'];
      });

      debugPrint('Payment Intent created: ${paymentIntent['id']}');
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      _showErrorMessage('Failed to initialize payment. Please try again.');
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _cardController.dispose();
    _cardHolderController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _cardHolderFocus.dispose();
    _emailFocus.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _postalCodeFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _processStripePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paymentIntentClientSecret == null) {
      _showErrorMessage('Payment not initialized. Please try again.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    _pulseController.repeat(reverse: true);

    try {
      // Create billing details
      final billingDetails = BillingDetails(
        name: _cardHolderController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: Address(
          line1: _addressController.text.trim(),
          line2: '', // Required parameter
          city: _cityController.text.trim(),
          state: '', // Required parameter - add empty string for Malaysia
          postalCode: _postalCodeController.text.trim(),
          country: 'MY', // Malaysia
        ),
      );

      // Confirm payment with Stripe
      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: _paymentIntentClientSecret!,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        // Payment successful
        await _updateBookingStatus('confirmed', paymentIntent.id);
        _showSuccessMessage();

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.paymentSuccess,
          (route) => false,
          arguments: {
            'bookingId': _bookingId,
            'bookingReference': _generateBookingReference(),
            'totalAmount': _totalAmount,
            'passengers': _passengers,
            'flightDetails': _bookingData,
            'paymentIntentId': paymentIntent.id,
          },
        );
      } else {
        // Payment failed or requires action
        setState(() {
          _errorMessage = 'Payment failed. Please try again.';
        });
        _showErrorMessage(_errorMessage!);
      }
    } on StripeException catch (e) {
      // Handle test cases specifically
      final errorMessage = _getTestCaseErrorMessage(e);
      setState(() {
        _errorMessage = errorMessage;
      });
      _showErrorMessage(errorMessage);

      // Log which test case was triggered
      if (errorMessage.contains('Payment declined. Use another card.')) {
        debugPrint('✅ NS02-FLG-4: Invalid payment test case triggered');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment processing failed. Please try again.';
      });
      _showErrorMessage(_errorMessage!);
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _updateBookingStatus(
      String status, String? paymentIntentId) async {
    try {
      if (_bookingId != null) {
        await _firestore.collection('bookings').doc(_bookingId).update({
          'status': status,
          'paymentCompletedAt': FieldValue.serverTimestamp(),
          'totalAmount': _totalAmount,
          'paymentIntentId': paymentIntentId,
          'paymentMethod': 'stripe',
        });
      }
    } catch (e) {
      debugPrint('Error updating booking status: $e');
    }
  }

  String _generateBookingReference() {
    return 'TT${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  }

  /// Get user-friendly error messages for test cases
  String _getTestCaseErrorMessage(StripeException error) {
    // For NS02-FLG-4: Always return the specified message for declined cards
    if ([
      'card_declined',
      'generic_decline',
      'insufficient_funds',
      'lost_card',
      'stolen_card',
      'expired_card',
      'incorrect_cvc',
      'processing_error'
    ].contains(error.error.code)) {
      return 'Payment declined. Use another card.';
    }

    // For other errors, provide specific messages
    switch (error.error.code) {
      case 'incorrect_number':
        return 'Your card number is incorrect.';
      case 'invalid_expiry_month':
      case 'invalid_expiry_year':
        return 'Your card\'s expiration date is incorrect.';
      case 'invalid_cvc':
        return 'Your card\'s security code is incorrect.';
      case 'rate_limit':
        return 'Too many requests. Please wait a moment and try again.';
      default:
        return error.error.localizedMessage ??
            'Payment failed. Please try again.';
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: successColor, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Payment Successful!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentSummary(),
                          const SizedBox(height: 24),
                          _buildStripeCardForm(),
                          const SizedBox(height: 24),
                          _buildBillingDetails(),
                          const SizedBox(height: 24),
                          _buildSecurityInfo(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: subtleGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: darkGrey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.security, color: successColor, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Powered by Stripe • SSL encrypted',
                      style: TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/stripe-logo.png',
            height: 32,
            width: 64,
            errorBuilder: (context, error, stackTrace) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Stripe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Booking Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_bookingData != null) ...[
            _buildSummaryRow('Route',
                '${_bookingData!['from'] ?? 'KUL'} → ${_bookingData!['to'] ?? 'SIN'}'),
            _buildSummaryRow('Date', _bookingData!['departureDate'] ?? 'Today'),
            _buildSummaryRow(
                'Passengers', '${_passengers?.length ?? 1} passenger(s)'),
            const Divider(height: 24),
          ],
          _buildSummaryRow('Subtotal',
              'RM ${(_totalAmount / 1.12 - 25).toStringAsFixed(2)}'),
          _buildSummaryRow('Taxes & Fees',
              'RM ${((_totalAmount / 1.12 - 25) * 0.12).toStringAsFixed(2)}'),
          _buildSummaryRow('Service Fee', 'RM 25.00'),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'RM ${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: darkGrey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripeCardForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Card Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stripe Card Form
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: CardFormField(
              controller: _cardController,
              style: CardFormStyle(
                backgroundColor: subtleGrey,
                textColor: textColor,
                fontSize: 16,
                placeholderColor: darkGrey,
                borderColor: Colors.grey.shade300,
                borderRadius: 12,
                borderWidth: 1,
                cursorColor: primaryColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Row(
            children: [
              Icon(Icons.security, color: successColor, size: 16),
              SizedBox(width: 8),
              Text(
                'Your payment information is secure and encrypted',
                style: TextStyle(
                  fontSize: 12,
                  color: darkGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Billing Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _cardHolderController,
            focusNode: _cardHolderFocus,
            label: 'Full Name',
            icon: Icons.person,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _emailFocus.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Email Address',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _phoneFocus.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            label: 'Phone Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _addressFocus.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            focusNode: _addressFocus,
            label: 'Address',
            icon: Icons.home,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _cityFocus.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  controller: _cityController,
                  focusNode: _cityFocus,
                  label: 'City',
                  icon: Icons.location_city,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _postalCodeFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _postalCodeController,
                  focusNode: _postalCodeFocus,
                  label: 'Postal Code',
                  icon: Icons.markunread_mailbox,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: successColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Secure Payment with Stripe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Test case information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧪 Test Cases (for testing only):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '✅ NS02-FLG-2: Valid Payment Test\n• Use: 4242 4242 4242 4242\n• Result: Payment successful → Redirect to confirmation\n',
                  style: TextStyle(
                    fontSize: 11,
                    color: darkGrey,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '❌ NS02-FLG-4: Invalid Payment Test\n• Use: Any other card number\n• Result: "Payment declined. Use another card."\n• User stays on payment page',
                  style: TextStyle(
                    fontSize: 11,
                    color: errorColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            '• Your payment is processed securely by Stripe\n• All card information is encrypted\n• We never store your card details\n• PCI DSS Level 1 compliant',
            style: TextStyle(
              fontSize: 12,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darkGrey),
        labelStyle: const TextStyle(color: darkGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: subtleGrey,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isProcessing ? _pulseAnimation.value : 1.0,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processStripePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isProcessing ? 0 : 4,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processing Payment...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay RM ${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
