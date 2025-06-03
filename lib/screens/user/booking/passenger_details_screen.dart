import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({super.key});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen>
    with TickerProviderStateMixin {
  // Enhanced color palette
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF10B981);
  static const Color textColor = Color(0xFF1E293B);
  static const Color subtleGrey = Color(0xFFF1F5F9);
  static const Color darkGrey = Color(0xFF64748B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Passenger data structure
  List<PassengerData> _passengers = [];
  int _currentPassengerIndex = 0;
  bool _isLoading = false;
  bool _autoSaveEnabled = true;
  String? _draftId;

  // Page state
  PageController _pageController = PageController();
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializePassengers();
    _loadUserProfile();
    _loadBookingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get booking data from previous screens
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingData = args;
      final adultsCount = args['adults'] as int? ?? 1;
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Start animations
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
          setState(() {
            _userProfile = doc.data();
          });
          _autofillFirstPassenger();
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  void _loadBookingData() {
    // Load any existing booking data if user is returning to this screen
  }

  void _autofillFirstPassenger() {
    if (_userProfile != null && _passengers.isNotEmpty) {
      final firstPassenger = _passengers[0];
      firstPassenger.fullNameController.text = _userProfile!['fullName'] ?? '';
      firstPassenger.emailController.text = _userProfile!['email'] ?? '';
      firstPassenger.phoneController.text = _userProfile!['phone'] ?? '';
      if (_userProfile!['nationality'] != null) {
        firstPassenger.nationality = _userProfile!['nationality'];
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
    for (var passenger in _passengers) {
      passenger.dispose();
    }
    super.dispose();
  }

  // Auto-save functionality
  void _autoSave() async {
    if (!_autoSaveEnabled) return;

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final draftData = {
          'userId': user.uid,
          'passengers': _passengers.map((p) => p.toMap()).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'bookingData': _bookingData,
        };

        if (_draftId == null) {
          final doc = await _firestore.collection('passenger_drafts').add(draftData);
          _draftId = doc.id;
        } else {
          await _firestore.collection('passenger_drafts').doc(_draftId).update(draftData);
        }
      }
    } catch (e) {
      print('Auto-save error: $e');
    }
  }

  // Form validation
  bool _validateCurrentPassenger() {
    return _passengers[_currentPassengerIndex].isValid();
  }

  bool _validateAllPassengers() {
    return _passengers.every((passenger) => passenger.isValid());
  }

  // Navigation between passengers
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
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Please fill in all required fields correctly'),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Date picker with enhanced UI
  Future<void> _selectDate(BuildContext context, int passengerIndex) async {
    final passenger = _passengers[passengerIndex];
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: passenger.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
        passenger.dateOfBirth = picked;
        passenger.dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
      _autoSave();
    }
  }

  // Nationality picker
  void _showNationalityPicker(int passengerIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NationalityPicker(
        selectedNationality: _passengers[passengerIndex].nationality,
        onSelected: (nationality) {
          setState(() {
            _passengers[passengerIndex].nationality = nationality;
          });
          _autoSave();
        },
      ),
    );
  }

  // Save all passengers
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
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create booking with passenger details
      final bookingData = {
        'userId': user.uid,
        'bookingId': _generateBookingId(),
        'passengers': _passengers.map((p) => p.toFirestoreMap()).toList(),
        'flightDetails': _bookingData,
        'status': 'pending_payment',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final bookingRef = await _firestore.collection('bookings').add(bookingData);

      // Delete draft if exists
      if (_draftId != null) {
        await _firestore.collection('passenger_drafts').doc(_draftId).delete();
      }

      // Show success message
      _showSuccessMessage();

      // Navigate to payment with booking ID
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.payment,
          arguments: {
            ...(_bookingData ?? {}),
            'bookingId': bookingRef.id,
            'passengers': _passengers.map((p) => p.toMap()).toList(),
          },
        );
      }
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
                Expanded(
                  child: _buildPassengerForm(),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: subtleGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              const SizedBox(width: 16),
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
                      'Step 3 of 4 • Almost there!',
                      style: TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
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
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                '${((_currentPassengerIndex + 1) / _passengers.length * 100).round()}% Complete',
                style: TextStyle(
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

  Widget _buildPassengerForm() {
    return PageView.builder(
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
            padding: const EdgeInsets.all(20),
            child: PassengerFormCard(
              passenger: _passengers[index],
              onDateSelect: () => _selectDate(context, index),
              onNationalitySelect: () => _showNationalityPicker(index),
              onFieldChanged: _autoSave,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPassengerIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousPassenger,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
            ),
          if (_currentPassengerIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextPassenger,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                          _currentPassengerIndex == _passengers.length - 1
                              ? 'Continue to Payment'
                              : 'Next Passenger',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPassengerIndex == _passengers.length - 1
                              ? Icons.payment
                              : Icons.arrow_forward,
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

// Passenger Data Model
class PassengerData {
  final int passengerNumber;
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController passportNumberController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  String nationality = 'Malaysia';
  DateTime? dateOfBirth;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  PassengerData(this.passengerNumber);

  bool isValid() {
    return formKey.currentState?.validate() ?? false;
  }

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

// Passenger Form Card Widget
class PassengerFormCard extends StatelessWidget {
  final PassengerData passenger;
  final VoidCallback onDateSelect;
  final VoidCallback onNationalitySelect;
  final VoidCallback onFieldChanged;

  const PassengerFormCard({
    super.key,
    required this.passenger,
    required this.onDateSelect,
    required this.onNationalitySelect,
    required this.onFieldChanged,
  });

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _PassengerDetailsScreenState.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: _PassengerDetailsScreenState.primaryColor,
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
                          color: _PassengerDetailsScreenState.textColor,
                        ),
                      ),
                      Text(
                        passenger.passengerNumber == 1 ? 'Primary passenger' : 'Additional passenger',
                        style: TextStyle(
                          fontSize: 14,
                          color: _PassengerDetailsScreenState.darkGrey,
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
                onChanged: (value) => onFieldChanged(),
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
                onChanged: (value) => onFieldChanged(),
              ),
              
              const SizedBox(height: 20),
              
              // Date of Birth and Nationality Row
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
                          final age = DateTime.now().year - passenger.dateOfBirth!.year;
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
              
              // Email
              _buildTextField(
                controller: passenger.emailController,
                label: 'Contact Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) => onFieldChanged(),
              ),
              
              const SizedBox(height: 20),
              
              // Phone
              _buildTextField(
                controller: passenger.phoneController,
                label: 'Contact Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 8) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
                onChanged: (value) => onFieldChanged(),
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
        prefixIcon: Icon(icon, color: _PassengerDetailsScreenState.darkGrey),
        labelStyle: TextStyle(color: _PassengerDetailsScreenState.darkGrey),
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
          borderSide: const BorderSide(color: _PassengerDetailsScreenState.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _PassengerDetailsScreenState.errorColor),
        ),
        filled: true,
        fillColor: _PassengerDetailsScreenState.subtleGrey,
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
        prefixIcon: Icon(Icons.calendar_today, color: _PassengerDetailsScreenState.darkGrey),
        suffixIcon: Icon(Icons.arrow_drop_down, color: _PassengerDetailsScreenState.darkGrey),
        labelStyle: TextStyle(color: _PassengerDetailsScreenState.darkGrey),
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
          borderSide: const BorderSide(color: _PassengerDetailsScreenState.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _PassengerDetailsScreenState.errorColor),
        ),
        filled: true,
        fillColor: _PassengerDetailsScreenState.subtleGrey,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _PassengerDetailsScreenState.subtleGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.flag, color: _PassengerDetailsScreenState.darkGrey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nationality,
                style: const TextStyle(
                  fontSize: 16,
                  color: _PassengerDetailsScreenState.textColor,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: _PassengerDetailsScreenState.darkGrey),
          ],
        ),
      ),
    );
  }
}

// Nationality Picker Widget
class NationalityPicker extends StatefulWidget {
  final String selectedNationality;
  final Function(String) onSelected;

  const NationalityPicker({
    super.key,
    required this.selectedNationality,
    required this.onSelected,
  });

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
    // Add more countries as needed
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
          .where((country) => country.toLowerCase().contains(query))
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country == widget.selectedNationality;
                
                return ListTile(
                  title: Text(
                    country,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _PassengerDetailsScreenState.primaryColor : null,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: _PassengerDetailsScreenState.primaryColor)
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