// lib/screens/user/booking/passenger_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/routes/app_routes.dart'; // Make sure this path matches your project

/// ─── “Violin” color palette (top-level constants) ───────────────────────────
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controllers (slide, fade, scale)
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Passenger data list
  List<PassengerData> _passengers = [];
  int _currentPassengerIndex = 0;
  bool _isLoading        = false;
  bool _autoSaveEnabled  = true;
  String? _draftId;

  // Optional user profile (for autofill)
  Map<String, dynamic>? _userProfile;

  // Booking-related data passed from previous route (e.g. { 'adults': 2, ... })
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
      final int adultsCount = args['adults'] as int? ?? 1;
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
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
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
      first.fullNameController.text      = _userProfile!['fullName']  ?? '';
      first.emailController.text         = _userProfile!['email']     ?? '';
      first.phoneController.text         = _userProfile!['phone']     ?? '';
      if (_userProfile!['nationality'] != null) {
        first.nationality = _userProfile!['nationality'];
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

  /// ─── Auto-save drafts (any Firestore permission error is caught) ───────────
  Future<void> _autoSave() async {
    if (!_autoSaveEnabled) return;
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final draftData = <String, dynamic>{
          'userId': user.uid,
          'passengers': _passengers.map((p) => p.toMap()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        if (_draftId == null) {
          final docRef = await _firestore.collection('passenger_drafts').add(draftData);
          _draftId = docRef.id;
        } else {
          await _firestore.collection('passenger_drafts').doc(_draftId).update(draftData);
        }
      }
    } catch (e) {
      // Print permission errors but do not crash the screen
      debugPrint('Auto-save error: $e');
    }
  }

  bool _validateCurrentPassenger() {
    return _passengers[_currentPassengerIndex].isValid();
  }

  bool _validateAllPassengers() {
    return _passengers.every((p) => p.isValid());
  }

  void _nextPassenger() {
    if (_currentPassengerIndex < _passengers.length - 1) {
      if (_validateCurrentPassenger()) {
        setState(() {
          _currentPassengerIndex++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _autoSave();
      } else {
        _showValidationError();
      }
    } else {
      // Last passenger: save them all
      _saveAllPassengers();
    }
  }

  void _previousPassenger() {
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
    final passenger = _passengers[passengerIndex];
    final DateTime now     = DateTime.now();
    final DateTime initial = passenger.dateOfBirth ?? now.subtract(const Duration(days: 365 * 25));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        passenger.dateOfBirth        = picked;
        passenger.dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      _autoSave();
    }
  }

  void _showNationalityPicker(int passengerIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NationalityPicker(
        selectedNationality: _passengers[passengerIndex].nationality,
        onSelected: (nat) {
          setState(() {
            _passengers[passengerIndex].nationality = nat;
          });
          _autoSave();
        },
      ),
    );
  }

  Future<void> _saveAllPassengers() async {
    if (!_validateAllPassengers()) {
      _showValidationError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Map<String, dynamic> bookingData = {
        'userId': user.uid,
        'bookingId': _generateBookingId(),
        'passengers': _passengers.map((p) => p.toFirestoreMap()).toList(),
        'flightDetails': _bookingData ?? <String, dynamic>{},
        'status': 'pending_payment',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference<Map<String, dynamic>> bookingRef =
          await _firestore.collection('bookings').add(bookingData);

      // Delete draft if it exists
      if (_draftId != null) {
        await _firestore.collection('passenger_drafts').doc(_draftId).delete();
      }

      _showSuccessMessage();

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.payment,
        arguments: {
          ...(_bookingData ?? <String, dynamic>{}),
          'bookingId': bookingRef.id,
          'passengers': _passengers.map((p) => p.toMap()).toList(),
        },
      );
    } catch (e) {
      _showErrorMessage('Failed to save passenger details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      resizeToAvoidBottomInset: true,  // ← ensure scaffold moves up when keyboard opens
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(child: _buildPassengerForm()),
                _buildBottomNavigation(),
              ],
            ),
          ),
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

              // Auto-save indicator
              if (_autoSaveEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Auto-save',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // “+ Add Passenger” button if this is the last passenger page
          if (isLastPassenger) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
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
            ),
          ],
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
    // Dynamically add extra bottom padding equal to the keyboard height + 90px
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + 90.0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: PageView.builder(
        controller: _pageController,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: PassengerFormCard(
                passenger: _passengers[index],
                onDateSelect: () => _selectDate(context, index),
                onNationalitySelect: () => _showNationalityPicker(index),
                onFieldChanged: _autoSave,
              ),
            ),
          );
        },
      ),
    );
  }

  /// ─── Bottom navigation: “Previous” / “Next” or “Continue to Payment” ──────
  Widget _buildBottomNavigation() {
    final bool isLast = (_currentPassengerIndex == _passengers.length - 1);

    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                          Icon(isLast ? Icons.payment : Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Passenger Data Model ─────────────────────────────────────────────────
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

  /// Used for storing in “passenger_drafts” or local debugging
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

  /// Used when writing into the “bookings” collection
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

/// ─── Passenger Form Card Widget ─────────────────────────────────────────────
class PassengerFormCard extends StatelessWidget {
  final PassengerData passenger;
  final VoidCallback onDateSelect;
  final VoidCallback onNationalitySelect;
  final VoidCallback onFieldChanged;

  const PassengerFormCard({
    Key? key,
    required this.passenger,
    required this.onDateSelect,
    required this.onNationalitySelect,
    required this.onFieldChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              // Header icon + text
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
                  Column(
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
                            ? 'Primary passenger'
                            : 'Additional passenger',
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Full Name
              _buildTextField(
                controller: passenger.fullNameController,
                label: 'Full Name (as per passport)',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (_) => onFieldChanged(),
              ),
              const SizedBox(height: 20),

              // Passport Number
              _buildTextField(
                controller: passenger.passportNumberController,
                label: 'Passport Number',
                icon: Icons.credit_card,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter passport number';
                  }
                  if (value.length < 6) {
                    return 'Invalid passport number';
                  }
                  return null;
                },
                onChanged: (_) => onFieldChanged(),
              ),
              const SizedBox(height: 20),

              // Date of Birth + Nationality side-by-side
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDateField(
                      controller: passenger.dobController,
                      label: 'Date of Birth',
                      onTap: onDateSelect,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select date of birth';
                        }
                        if (passenger.dateOfBirth != null) {
                          final age =
                              DateTime.now().year - passenger.dateOfBirth!.year;
                          if (age < 0 || age > 120) {
                            return 'Invalid date of birth';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildNationalityField(
                      nationality: passenger.nationality,
                      onTap: onNationalitySelect,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact Email
              _buildTextField(
                controller: passenger.emailController,
                label: 'Contact Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                onChanged: (_) => onFieldChanged(),
              ),
              const SizedBox(height: 20),

              // Contact Phone
              _buildTextField(
                controller: passenger.phoneController,
                label: 'Contact Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone';
                  }
                  if (value.length < 8) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
                onChanged: (_) => onFieldChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: darkGrey),
        labelStyle: TextStyle(color: darkGrey),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today, color: darkGrey),
        suffixIcon: Icon(Icons.arrow_drop_down, color: darkGrey),
        labelStyle: TextStyle(color: darkGrey),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildNationalityField({
    required String nationality,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: subtleGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: darkGrey, size: 20),
            const SizedBox(width: 12),
            // Force single-line + ellipsis if too long
            Expanded(
              child: Text(
                nationality,
                style: const TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: darkGrey),
          ],
        ),
      ),
    );
  }
}

/// ─── Nationality Picker ─────────────────────────────────────────────────────
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
    // (add more countries as needed)
  ];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
    _searchController.addListener(_filterCountries);
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Nationality',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search countries...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                  title: Text(
                    country,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? primaryColor : null,
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