// lib/screens/user/flight/flight_search_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  State<FlightSearchPage> createState() => _FlightSearchPageState();
}

class _FlightSearchPageState extends State<FlightSearchPage> with TickerProviderStateMixin {
  // Violin color palette (matching OnboardingScreen) - STRICTLY FOLLOWING
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E);  // Muted Brown

  // Form data
  final _formKey = GlobalKey<FormState>();
  String? _departureCity;
  String? _arrivalCity;
  DateTime? _departureDate;
  DateTime? _returnDate;
  int _passengers = 1;
  String _selectedClass = 'Economy';
  String _selectedSeatType = 'Standard';
  bool _isRoundTrip = false;
  bool _isStudentFare = true;
  bool _isFlexibleDates = false;
  bool _needsHotel = false;
  bool _needsTransport = false;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _searchButtonController;
  late Animation<double> _searchButtonScale;

  // Enhanced popular routes with more details
  final List<Map<String, dynamic>> _popularRoutes = [
    {
      'from': 'Kuala Lumpur (KUL)',
      'to': 'Singapore (SIN)',
      'fromCode': 'KUL',
      'toCode': 'SIN',
      'duration': '1h 20m',
      'airlines': ['Malaysia Airlines', 'AirAsia'],
      'price': 189,
      'discount': 30,
    },
    {
      'from': 'Kuala Lumpur (KUL)',
      'to': 'Bangkok (BKK)',
      'fromCode': 'KUL',
      'toCode': 'BKK',
      'duration': '2h 5m',
      'airlines': ['Thai Airways', 'AirAsia'],
      'price': 299,
      'discount': 25,
    },
    {
      'from': 'Kuala Lumpur (KUL)',
      'to': 'Bali (DPS)',
      'fromCode': 'KUL',
      'toCode': 'DPS',
      'duration': '3h 15m',
      'airlines': ['Malaysia Airlines', 'Garuda'],
      'price': 459,
      'discount': 35,
    },
    {
      'from': 'Johor Bahru (JHB)',
      'to': 'Kuala Lumpur (KUL)',
      'fromCode': 'JHB',
      'toCode': 'KUL',
      'duration': '1h 15m',
      'airlines': ['Malaysia Airlines', 'AirAsia'],
      'price': 129,
      'discount': 20,
    },
    {
      'from': 'Kuala Lumpur (KUL)',
      'to': 'Penang (PEN)',
      'fromCode': 'KUL',
      'toCode': 'PEN',
      'duration': '1h 30m',
      'airlines': ['Malaysia Airlines', 'AirAsia'],
      'price': 159,
      'discount': 25,
    },
    {
      'from': 'Kuala Lumpur (KUL)',
      'to': 'Langkawi (LGK)',
      'fromCode': 'KUL',
      'toCode': 'LGK',
      'duration': '1h 45m',
      'airlines': ['Malaysia Airlines', 'AirAsia'],
      'price': 199,
      'discount': 30,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _searchButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _searchButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _searchButtonController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background dotted pattern
          Positioned.fill(
            child: CustomPaint(
              painter: DottedPatternPainter(color: primaryColor.withOpacity(0.02)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildEnhancedHeader(),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, _) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildContent(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Search Flights",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  "Student Exclusive Rates",
                  style: TextStyle(
                    fontSize: 14,
                    color: accentOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_isStudentFare)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentOrange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 16, color: accentOrange),
                  const SizedBox(width: 6),
                  Text(
                    "30% OFF",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentOrange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentFareCard(),
            const SizedBox(height: 24),
            _buildTripTypeSelector(),
            const SizedBox(height: 24),
            _buildLocationCard(),
            const SizedBox(height: 24),
            _buildDateCard(),
            const SizedBox(height: 24),
            _buildPassengersAndClassCard(),
            const SizedBox(height: 24),
            _buildAdditionalServicesCard(),
            const SizedBox(height: 24),
            _buildFlexibleDatesOption(),
            const SizedBox(height: 32),
            _buildEnhancedSearchButton(),
            const SizedBox(height: 32),
            _buildPopularRoutes(),
            const SizedBox(height: 32),
            _buildRecentSearches(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentFareCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _isStudentFare 
          ? LinearGradient(colors: [accentOrange.withOpacity(0.8), accentOrange])
          : LinearGradient(colors: [subtleGrey.withOpacity(0.5), subtleGrey]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (_isStudentFare ? accentOrange : subtleGrey).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isStudentFare ? Icons.school : Icons.school_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isStudentFare ? "Student Fare Activated" : "Enable Student Discount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isStudentFare 
                    ? "Save up to 30% with your student ID"
                    : "Verify student status to save money",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isStudentFare,
            onChanged: (value) {
              setState(() {
                _isStudentFare = value;
              });
            },
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildTripTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            Expanded(
              child: _buildTripTypeButton(
                "One Way",
                !_isRoundTrip,
                Icons.trending_flat,
                () => setState(() => _isRoundTrip = false),
              ),
            ),
            Expanded(
              child: _buildTripTypeButton(
                "Round Trip",
                _isRoundTrip,
                Icons.swap_horiz,
                () => setState(() => _isRoundTrip = true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripTypeButton(String text, bool isSelected, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : darkGrey),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isSelected ? Colors.white : darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationField(
            label: "From",
            hint: "Departure Airport",
            icon: Icons.flight_takeoff,
            value: _departureCity,
            onTap: () => _showAirportSelector(true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Divider(color: subtleGrey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GestureDetector(
                    onTap: _swapLocations,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.swap_vert, color: primaryColor, size: 22),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: subtleGrey)),
              ],
            ),
          ),
          _buildLocationField(
            label: "To",
            hint: "Arrival Airport",
            icon: Icons.flight_land,
            value: _arrivalCity,
            onTap: () => _showAirportSelector(false),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      color: value != null ? textColor : darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: darkGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateField(
            label: "Departure Date",
            value: _departureDate,
            onTap: () => _selectDate(true),
            icon: Icons.calendar_today,
          ),
          if (_isRoundTrip) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: subtleGrey),
            ),
            _buildDateField(
              label: "Return Date",
              value: _returnDate,
              onTap: () => _selectDate(false),
              icon: Icons.event_repeat,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    String displayText = "Select Date";
    String? dayInfo;

    if (value != null) {
      displayText = DateFormat('EEE, MMM dd').format(value);
      dayInfo = DateFormat('yyyy').format(value);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      color: value != null ? textColor : darkGrey,
                    ),
                  ),
                  if (dayInfo != null)
                    Text(
                      dayInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: accentOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: darkGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersAndClassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showPassengerSelector,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.people, size: 24, color: primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Passengers & Class",
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'} • $_selectedClass",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: darkGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalServicesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.add_business, size: 20, color: primaryColor),
            const SizedBox(width: 8),
            const Text(
              "Additional Services",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Hotel booking option
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.hotel, color: accentOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Hotel Booking",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Save up to 25% on hotel stays",
                        style: TextStyle(
                          fontSize: 12,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _needsHotel,
                  onChanged: (value) {
                    setState(() {
                      _needsHotel = value;
                    });
                  },
                  activeColor: accentOrange,
                  activeTrackColor: accentOrange.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        
        // Transport booking option
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, color: accentGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Ground Transport",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Airport transfers & car rentals",
                        style: TextStyle(
                          fontSize: 12,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _needsTransport,
                  onChanged: (value) {
                    setState(() {
                      _needsTransport = value;
                    });
                  },
                  activeColor: accentGreen,
                  activeTrackColor: accentGreen.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        
        // Seat preference info (non-economy clickable)
        if (_selectedClass != 'Economy') ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentOrange.withOpacity(0.3)),
            ),
            child: InkWell(
              onTap: () {
                // Navigate to seat selection page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Navigating to seat selection for $_selectedClass'),
                    backgroundColor: accentOrange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.airline_seat_recline_extra, color: accentOrange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Your $_selectedClass Seat",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Choose your preferred seat location",
                            style: TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Select",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlexibleDatesOption() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.date_range, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Flexible Dates",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Find cheaper flights ±3 days",
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isFlexibleDates,
              onChanged: (value) {
                setState(() {
                  _isFlexibleDates = value;
                });
              },
              activeColor: primaryColor,
              activeTrackColor: primaryColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchButton() {
    return AnimatedBuilder(
      animation: _searchButtonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchButtonScale.value,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                _searchButtonController.forward().then((_) {
                  _searchButtonController.reverse();
                });
                _searchFlights();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 24, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    "Search Flights",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_isStudentFare) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Student Rates",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopularRoutes() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(Icons.trending_up, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          const Text(
            "Popular Student Routes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 220, // ✅ Increased from 200 to 220 to prevent overflow
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _popularRoutes.length,
          itemBuilder: (context, index) {
            final route = _popularRoutes[index];
            return Container(
              width: 280,
              margin: EdgeInsets.only(right: index < _popularRoutes.length - 1 ? 16 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _departureCity = route['from'];
                    _arrivalCity = route['to'];
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with gradient
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        gradient: LinearGradient(
                          colors: [primaryColor.withOpacity(0.8), secondaryColor.withOpacity(0.6)],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${route['discount']}% OFF",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${route['fromCode']} → ${route['toCode']}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  route['duration'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content section with flexible height
                    Expanded( // ✅ Use Expanded to prevent overflow
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ Distribute space evenly
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible( // ✅ Use Flexible for responsive text
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "From",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: darkGrey,
                                        ),
                                      ),
                                      Text(
                                        "RM${route['price']}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: accentOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.flight_takeoff, color: primaryColor, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              route['airlines'].join(" • "),
                              style: TextStyle(
                                fontSize: 12,
                                color: darkGrey,
                              ),
                              maxLines: 2, // ✅ Limit text to 2 lines
                              overflow: TextOverflow.ellipsis, // ✅ Handle text overflow
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
  // Continue with existing methods (passenger selector, airport selector, etc.)
  void _showPassengerSelector() {
    final classes = ['Economy', 'Premium Economy', 'Business', 'First Class'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: subtleGrey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Passengers & Class",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Passengers",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _passengers > 1
                                      ? primaryColor.withOpacity(0.1)
                                      : subtleGrey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  size: 18,
                                  color: _passengers > 1 ? primaryColor : darkGrey,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _passengers.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _passengers < 9 ? () => setState(() => _passengers++) : null,
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _passengers < 9
                                      ? primaryColor.withOpacity(0.1)
                                      : subtleGrey.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 18,
                                  color: _passengers < 9 ? primaryColor : darkGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      "Travel Class",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final className = classes[index];
                          final isSelected = _selectedClass == className;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedClass = className;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (className == 'Economy'
                                        ? accentOrange.withOpacity(0.15)
                                        : primaryColor.withOpacity(0.1))
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryColor : subtleGrey,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected ? primaryColor : darkGrey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    className,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? primaryColor : textColor,
                                    ),
                                  ),
                                  if (_isStudentFare && className == 'Economy') ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentOrange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "30% OFF",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: accentOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Apply",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAirportSelector(bool isDeparture) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: subtleGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isDeparture ? "Select Departure" : "Select Destination",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search airports",
                      prefixIcon: Icon(Icons.search, color: darkGrey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        "Malaysian Airports",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildAirportTile("Kuala Lumpur (KUL)", "Kuala Lumpur International", isDeparture),
                        _buildAirportTile("Penang (PEN)", "Penang International", isDeparture),
                        _buildAirportTile("Langkawi (LGK)", "Langkawi International", isDeparture),
                        _buildAirportTile("Kota Kinabalu (BKI)", "Kota Kinabalu International", isDeparture),
                        _buildAirportTile("Johor Bahru (JHB)", "Senai International", isDeparture),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),
                        Row(
                          children: [
                            Icon(Icons.public, size: 20, color: primaryColor),
                            const SizedBox(width: 8),
                            const Text(
                              "Popular International",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildAirportTile("Singapore (SIN)", "Changi Airport", isDeparture),
                        _buildAirportTile("Bangkok (BKK)", "Suvarnabhumi Airport", isDeparture),
                        _buildAirportTile("Bali (DPS)", "Ngurah Rai International", isDeparture),
                        _buildAirportTile("Hong Kong (HKG)", "Hong Kong International", isDeparture),
                        _buildAirportTile("Tokyo (NRT)", "Narita International", isDeparture),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAirportTile(String code, String name, bool isDeparture) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDeparture ? Icons.flight_takeoff : Icons.flight_land,
          color: primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        code,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          color: darkGrey,
        ),
      ),
      onTap: () {
        setState(() {
          if (isDeparture) {
            _departureCity = code;
          } else {
            _arrivalCity = code;
          }
        });
        Navigator.pop(context);
      },
    );
  }

  void _swapLocations() {
    setState(() {
      final temp = _departureCity;
      _departureCity = _arrivalCity;
      _arrivalCity = temp;
    });
  }

  Future<void> _selectDate(bool isDeparture) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isDeparture
        ? _departureDate ?? now
        : _returnDate ?? (_departureDate ?? now).add(const Duration(days: 7));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: backgroundColor,
              onSurface: textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDeparture) {
          _departureDate = picked;
          if (_isRoundTrip && _returnDate != null && _returnDate!.isBefore(picked)) {
            _returnDate = picked.add(const Duration(days: 7));
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _searchFlights() {
    if (_departureCity == null || _arrivalCity == null || _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_isRoundTrip && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a return date'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    _saveRecentSearch();

    final originCode = _extractIata(_departureCity!);
    final destinationCode = _extractIata(_arrivalCity!);
    final departureDateStr = DateFormat('yyyy-MM-dd').format(_departureDate!);

    Navigator.pushNamed(
      context,
      '/flight-results',
      arguments: {
        'originCode': originCode,
        'destinationCode': destinationCode,
        'departureDate': departureDateStr,
        'adults': _passengers,
        'travelClass': _selectedClass.toUpperCase(),
        'direct': false,
        'isStudentFare': _isStudentFare,
        'needsHotel': _needsHotel,
        'needsTransport': _needsTransport,
        'isFlexibleDates': _isFlexibleDates,
      },
    );
  }

  String _extractIata(String fullString) {
    final match = RegExp(r'\((\w{3})\)').firstMatch(fullString);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    return fullString;
  }

  Future<void> _saveRecentSearch() async {
    try {
      await _firestore.collection('recentSearches').add({
        'userId': _auth.currentUser?.uid,
        'departure': _departureCity,
        'arrival': _arrivalCity,
        'date': _departureDate,
        'passengers': '$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'}',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving recent search: $e');
    }
  }

  Widget _buildRecentSearches() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('recentSearches')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      "Recent Searches",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    "Clear All",
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...snapshot.data!.docs.map((doc) {
              final search = doc.data() as Map<String, dynamic>;
              return _buildRecentSearchItem(
                departure: search['departure'] ?? '',
                arrival: search['arrival'] ?? '',
                date: DateFormat('MMM dd, yyyy').format(
                  (search['date'] as Timestamp).toDate(),
                ),
                passengers: search['passengers'] ?? '1 Passenger',
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearchItem({
    required String departure,
    required String arrival,
    required String date,
    required String passengers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _departureCity = departure;
            _arrivalCity = arrival;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: subtleGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history, color: darkGrey, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          departure.split(' ')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          arrival.split(' ')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$date • $passengers",
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.north_east, color: primaryColor, size: 20),
                onPressed: () {
                  setState(() {
                    _departureCity = departure;
                    _arrivalCity = arrival;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearRecentSearches() async {
    try {
      final batch = _firestore.batch();
      final searches = await _firestore
          .collection('recentSearches')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .get();

      for (final doc in searches.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recent searches cleared'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }
}

/// ────────────────────────────────────────────────────────────────
/// Dotted Pattern Painter
/// ────────────────────────────────────────────────────────────────
class DottedPatternPainter extends CustomPainter {
  final Color color;
  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        if ((x + y) % 60 == 0) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}