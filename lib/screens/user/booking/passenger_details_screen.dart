// lib/screens/user/booking/passenger_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/routes/app_routes.dart'; // adjust as needed

/// ─── “Violin” color palette (top‐level constants) ───────────────────────────
const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
const Color primaryColor     = Color(0xFF5C2E00); // Dark Brown
const Color secondaryColor   = Color(0xFF8B5000); // Amber Brown
const Color textColor        = Color(0xFF35281E); // Deep Wood
const Color subtleGrey       = Color(0xFFDAC1A7); // Light Tan
const Color darkGrey         = Color(0xFF7E5E3C); // Medium Brown
const Color accentColor      = Color(0xFFD4A373); // Warm Highlight
const Color errorColor       = Color(0xFFEF4444); // Red for errors

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen>
    with TickerProviderStateMixin {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // Animation controllers (slide, fade, scale)
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset>   _slideAnimation;
  late Animation<double>   _fadeAnimation;
  late Animation<double>   _scaleAnimation;

  // Passenger data
  List<PassengerData> _passengers = [];
  int _currentPassengerIndex = 0;
  bool _isLoading = false;

  // Optional user profile (for autofill)
  Map<String, dynamic>? _userProfile;

  // Booking‐related data passed from previous route
  Map<String, dynamic>? _bookingData;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePassengers();    // default to 1 passenger
    _loadUserProfile();         // attempt to autofill from user document
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If this screen was pushed with arguments (e.g. {'adults': 2, ...}), pick them up:
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingData = args;
      final int adultsCount = (args['adults'] as int?) ?? 1;
      _initializePassengers(count: adultsCount);
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
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
  }

  void _initializePassengers({int count = 1}) {
    _passengers = List.generate(count, (index) => PassengerData(index + 1));
    setState(() {});
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _userProfile = doc.data();
          _autofillFirstPassenger();
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  void _autofillFirstPassenger() {
    if (_userProfile != null && _passengers.isNotEmpty) {
      final first = _passengers[0];
      first.fullNameController.text      = (_userProfile!['fullName']  ?? '').toString();
      first.emailController.text         = (_userProfile!['email']     ?? '').toString();
      first.phoneController.text         = (_userProfile!['phone']     ?? '').toString();
      if (_userProfile!['nationality'] != null) {
        first.nationality = _userProfile!['nationality'].toString();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController.dispose();
    for (var p in _passengers) {
      p.dispose();
    }
    super.dispose();
  }

  bool _validateCurrentPassenger() {
    final passenger = _passengers[_currentPassengerIndex];
    return passenger.isValid();
  }

  bool _validateAllPassengers() {
    return _passengers.every((p) => p.isValid());
  }

  void _nextPassenger() {
    // Unfocus current field before moving
    FocusScope.of(context).unfocus();

    if (_currentPassengerIndex < _passengers.length - 1) {
      if (_validateCurrentPassenger()) {
        setState(() {
          _currentPassengerIndex++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _showValidationError();
      }
    } else {
      // Last passenger: save them all
      _saveAllPassengers();
    }
  }

  void _previousPassenger() {
    FocusScope.of(context).unfocus();

    if (_currentPassengerIndex > 0) {
      setState(() {
        _currentPassengerIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('Please fill in all required fields')),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, int passengerIndex) async {
    // Unfocus any active text fields
    FocusScope.of(context).unfocus();

    final passenger = _passengers[passengerIndex];
    final now     = DateTime.now();
    final initial = passenger.dateOfBirth ?? now.subtract(const Duration(days: 365 * 25));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: backgroundColor,
              surface: backgroundColor,
              onSurface: textColor,
              secondary: accentColor,
              onSecondary: backgroundColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
            dialogBackgroundColor: backgroundColor,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        passenger.dateOfBirth        = picked;
        passenger.dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showNationalityPicker(int passengerIndex) {
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NationalityPicker(
        selectedNationality: _passengers[passengerIndex].nationality,
        onSelected: (nat) {
          if (mounted) {
            setState(() {
              _passengers[passengerIndex].nationality = nat;
            });
          }
        },
      ),
    );
  }

  Future<void> _saveAllPassengers() async {
    if (!_validateAllPassengers()) {
      _showValidationError();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final primaryPassenger = _passengers.isNotEmpty ? _passengers[0] : null;

      final bookingData = <String, dynamic>{
        'userId': user.uid,
        'bookingId': _generateBookingId(),
        'passengers': _passengers.map((p) => p.toFirestoreMap()).toList(),
        'flightDetails': _bookingData ?? <String, dynamic>{},
        'status': 'pending_payment',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'primaryPassengerBilling': primaryPassenger?.getBillingDetails(),
        'passengerCount': _passengers.length,
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);

      _showSuccessMessage();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.payment,
        arguments: {
          ...(_bookingData ?? <String, dynamic>{}),
          'bookingId': docRef.id,
          'passengers': _passengers.map((p) => p.toMap()).toList(),
          'primaryPassengerBilling': primaryPassenger?.getBillingDetails(),
          'basePrice': _bookingData?['price'] ?? 299.0,
          'adults': _bookingData?['adults'] ?? _passengers.length,
          'children': _bookingData?['children'] ?? 0,
          'departureDate': _bookingData?['departureDate'] ?? 'Today',
          'departureTime': _bookingData?['departureTime'] ?? '10:30 AM',
          'from': _bookingData?['from'] ?? 'KUL',
          'to': _bookingData?['to'] ?? 'SIN',
          'fromCity': _bookingData?['fromCity'] ?? 'Kuala Lumpur',
          'toCity': _bookingData?['toCity'] ?? 'Singapore',
          'flightNumber': _bookingData?['flightNumber'] ?? 'TT 101',
          'source': 'passenger_details',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _showErrorMessage('Failed to save passenger details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _generateBookingId() {
    return 'TT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
              child: const Icon(Icons.check, color: accentColor, size: 16),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Passenger details saved successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: accentColor,
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
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // only animate the header:
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildHeader(),
              ),
            ),

            _buildProgressIndicator(),

            Expanded(
              child: _buildPassengerForm(),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  /// ─── Header (with “+ Add Passenger” on last page) ─────────────────────────
  Widget _buildHeader() {
    final bool isLastPassenger = (_currentPassengerIndex == _passengers.length - 1);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
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

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Passenger Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Step ${_currentPassengerIndex + 1} of ${_passengers.length}  •  Almost there!',
                      style: const TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // “+ Add Passenger” button if this is the last page
              if (isLastPassenger) ...[
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _passengers.add(PassengerData(_passengers.length + 1));
                      _currentPassengerIndex = _passengers.length - 1;
                    });
                    _pageController.animateToPage(
                      _passengers.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.add, color: primaryColor, size: 20),
                  label: const Text(
                    'Add Passenger',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: primaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// ─── Progress indicator (simple linear) ─────────────────────────────────
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Passenger ${_currentPassengerIndex + 1} of ${_passengers.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${((_currentPassengerIndex + 1) / _passengers.length * 100).round()}% Done',
                style: const TextStyle(
                  fontSize: 14,
                  color: darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentPassengerIndex + 1) / _passengers.length,
            backgroundColor: subtleGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  /// ─── The PageView that shows each passenger’s form ─────────────────────────
  Widget _buildPassengerForm() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe
      onPageChanged: (index) {
        setState(() {
          _currentPassengerIndex = index;
        });
      },
      itemCount: _passengers.length,
      itemBuilder: (context, index) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              // Make room for the keyboard so that fields remain visible:
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: PassengerFormCard(
              passenger: _passengers[index],
              onDateSelect: () => _selectDate(context, index),
              onNationalitySelect: () => _showNationalityPicker(index),
            ),
          ),
        );
      },
    );
  }

  /// ─── Bottom navigation: “Previous” / “Next” or “Continue to Payment” ──────
  Widget _buildBottomNavigation() {
    final bool isLast = (_currentPassengerIndex == _passengers.length - 1);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          if (_currentPassengerIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPassenger,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          if (_currentPassengerIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPassenger,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Continue to Payment' : 'Next Passenger',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isLast ? Icons.payment : Icons.arrow_forward,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Data model for each passenger ────────────────────────────────────────
class PassengerData {
  final int passengerNumber;

  final TextEditingController fullNameController       = TextEditingController();
  final TextEditingController passportNumberController = TextEditingController();
  final TextEditingController dobController            = TextEditingController();
  final TextEditingController emailController          = TextEditingController();
  final TextEditingController phoneController          = TextEditingController();

  String nationality = 'Malaysia';
  DateTime? dateOfBirth;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  PassengerData(this.passengerNumber);

  bool isValid() {
    return formKey.currentState?.validate() ?? false;
  }

  /// For “passenger_drafts” (no longer used, but kept for consistency)
  Map<String, dynamic> toMap() {
    return {
      'passengerNumber': passengerNumber,
      'fullName': fullNameController.text.trim(),
      'passportNumber': passportNumberController.text.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'nationality': nationality,
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
    };
  }

  /// If you want to store to a “bookings” collection:
  Map<String, dynamic> toFirestoreMap() {
    return {
      'fullName': fullNameController.text.trim(),
      'passportNumber': passportNumberController.text.trim(),
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'contactEmail': emailController.text.trim(),
      'contactPhone': phoneController.text.trim(),
      'age': dateOfBirth != null
          ? DateTime.now().year - dateOfBirth!.year
          : null,
      'isPrimaryPassenger': passengerNumber == 1,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// If you need billing details for the payment screen:
  Map<String, dynamic> getBillingDetails() {
    return {
      'name': fullNameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'nationality': nationality,
      'isPrimaryPassenger': passengerNumber == 1,
    };
  }

  void dispose() {
    fullNameController.dispose();
    passportNumberController.dispose();
    dobController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}

/// ─── Each passenger’s form card ────────────────────────────────────────────
class PassengerFormCard extends StatelessWidget {
  final PassengerData passenger;
  final VoidCallback onDateSelect;
  final VoidCallback onNationalitySelect;

  const PassengerFormCard({
    Key? key,
    required this.passenger,
    required this.onDateSelect,
    required this.onNationalitySelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: passenger.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header icon + text ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // → Wrap Column in Expanded to avoid overflow:
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger ${passenger.passengerNumber}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          passenger.passengerNumber == 1
                              ? 'Primary passenger • Will be used for billing'
                              : 'Additional passenger',
                          style: TextStyle(
                            fontSize: 14,
                            color: passenger.passengerNumber == 1
                                ? accentColor
                                : darkGrey,
                            fontWeight: passenger.passengerNumber == 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ─── Full Name ─────────────────────────────────────────────────────────
              _buildTextField(
                controller: passenger.fullNameController,
                label: 'Full Name (as per passport)',
                icon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().split(' ').length < 2) {
                    return 'Please enter both first and last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Passport Number ───────────────────────────────────────────────────
              _buildTextField(
                controller: passenger.passportNumberController,
                label: 'Passport Number',
                icon: Icons.credit_card,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter passport number';
                  }
                  if (value.length < 6) {
                    return 'Invalid passport number';
                  }
                  final cleanPassport = value.replaceAll(' ', '').toUpperCase();
                  if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanPassport)) {
                    return 'Passport should contain only letters & numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Date of Birth + Nationality (side‐by‐side) ────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildDateField(
                      controller: passenger.dobController,
                      label: 'Date of Birth',
                      onTap: onDateSelect,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select date';
                        }
                        if (passenger.dateOfBirth != null) {
                          final age =
                              DateTime.now().year - passenger.dateOfBirth!.year;
                          if (age < 0 || age > 120) {
                            return 'Invalid date';
                          }
                          if (age < 16) {
                            return 'Must be 16+';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: _buildNationalityField(
                      nationality: passenger.nationality,
                      onTap: onNationalitySelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Contact Email (with stronger validation) ─────────────────────────
              _buildTextField(
                controller: passenger.emailController,
                label: passenger.passengerNumber == 1
                    ? 'Contact Email (for billing & confirmation)'
                    : 'Contact Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {},
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  final domain = value.split('@').last.toLowerCase();
                  if (domain.contains(' ') || domain.contains('..')) {
                    return 'Invalid email domain';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Contact Phone (digits only, 8–15 digits) ─────────────────────────
              _buildTextField(
                controller: passenger.phoneController,
                label: passenger.passengerNumber == 1
                    ? 'Contact Phone (for billing & updates)'
                    : 'Contact Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone';
                  }
                  final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                  if (cleanPhone.length < 8 || cleanPhone.length > 15) {
                    return 'Enter a valid phone (8–15 digits)';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
                    return 'Phone should contain only digits';
                  }
                  return null;
                },
              ),

              // ─── Info banner for primary passenger ──────────────────────────────
              if (passenger.passengerNumber == 1) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This passenger’s details will be used for payment billing '
                          'and booking confirmation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ─── Helper: Generic TextFormField builder ─────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(color: textColor, fontSize: 16),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  /// ─── Read‐only date field that opens a date picker ───────────────────────
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: IgnorePointer(
        child: TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: textColor, fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today, color: darkGrey),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: darkGrey),
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
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  /// ─── Nationality selector box ────────────────────────────────────────────
  Widget _buildNationalityField({
    required String nationality,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: darkGrey, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                nationality,
                style: const TextStyle(fontSize: 16, color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: darkGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

/// ─── Bottom sheet to pick nationality ─────────────────────────────────────
class NationalityPicker extends StatefulWidget {
  final String selectedNationality;
  final Function(String) onSelected;

  const NationalityPicker({
    Key? key,
    required this.selectedNationality,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<NationalityPicker> createState() => _NationalityPickerState();
}

class _NationalityPickerState extends State<NationalityPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredCountries = [];

  final List<String> _countries = [
    'Malaysia', 'Singapore', 'Thailand', 'Indonesia', 'Philippines',
    'Vietnam', 'Cambodia', 'Laos', 'Myanmar', 'Brunei',
    'United States', 'United Kingdom', 'Canada', 'Australia',
    'New Zealand', 'Japan', 'South Korea', 'China', 'India',
    'Germany', 'France', 'Italy', 'Spain', 'Netherlands',
    'Belgium', 'Switzerland', 'Austria', 'Sweden', 'Norway',
    'Denmark', 'Finland', 'Poland', 'Czech Republic', 'Hungary',
    'Portugal', 'Greece', 'Ireland', 'Luxembourg', 'Croatia',
    'Slovenia', 'Slovakia', 'Estonia', 'Latvia', 'Lithuania',
    'Bulgaria', 'Romania', 'Cyprus', 'Malta', 'Iceland',
    'Brazil', 'Argentina', 'Chile', 'Colombia', 'Peru',
    'Mexico', 'Venezuela', 'Ecuador', 'Uruguay', 'Paraguay',
    'Bolivia', 'Costa Rica', 'Panama', 'Guatemala', 'Honduras',
    'El Salvador', 'Nicaragua', 'Cuba', 'Dominican Republic', 'Jamaica',
    'Trinidad and Tobago', 'Barbados', 'Bahamas', 'Haiti', 'Guyana',
    'Suriname', 'French Guiana', 'South Africa', 'Egypt', 'Nigeria',
    'Kenya', 'Ghana', 'Ethiopia', 'Morocco', 'Tunisia',
    'Algeria', 'Libya', 'Sudan', 'Tanzania', 'Uganda',
    'Zimbabwe', 'Zambia', 'Botswana', 'Namibia', 'Angola',
    'Mozambique', 'Madagascar', 'Mauritius', 'Seychelles', 'Comoros',
    'Russia', 'Ukraine', 'Belarus', 'Moldova', 'Georgia',
    'Armenia', 'Azerbaijan', 'Kazakhstan', 'Uzbekistan', 'Turkmenistan',
    'Kyrgyzstan', 'Tajikistan', 'Afghanistan', 'Pakistan', 'Bangladesh',
    'Sri Lanka', 'Nepal', 'Bhutan', 'Maldives', 'Iran',
    'Iraq', 'Turkey', 'Syria', 'Lebanon', 'Jordan',
    'Israel', 'Palestine', 'Saudi Arabia', 'Yemen', 'Oman',
    'United Arab Emirates', 'Qatar', 'Bahrain', 'Kuwait', 'Mongolia',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
    _searchController.addListener(_filterCountries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = _countries
          .where((c) => c.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: subtleGrey),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: darkGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Nationality',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    hintStyle: TextStyle(color: darkGrey.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: darkGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: subtleGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: subtleGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (ctx, index) {
                final country = _filteredCountries[index];
                final isSelected = country == widget.selectedNationality;
                return ListTile(
                  tileColor: isSelected ? accentColor.withOpacity(0.1) : null,
                  title: Text(
                    country,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? primaryColor : textColor,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: primaryColor)
                      : null,
                  onTap: () {
                    widget.onSelected(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}