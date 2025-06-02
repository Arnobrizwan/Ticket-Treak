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
  // Violin color palette (matching OnboardingScreen)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor      = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor    = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor         = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey        = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey          = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange      = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen       = Color(0xFFB28F5E);  // Muted Brown

  // Form data
  final _formKey = GlobalKey<FormState>();
  String?    _departureCity;
  String?    _arrivalCity;
  DateTime?  _departureDate;
  DateTime?  _returnDate;
  int        _passengers     = 1;
  String     _selectedClass  = 'Economy';
  bool       _isRoundTrip    = false;
  bool       _isStudentFare  = true;

  // Firebase (for recent searches, etc.)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // Animation
  late AnimationController _animationController;
  late Animation<double>   _fadeAnimation;

  // “Popular Student Routes”
  final List<Map<String,String>> _popularRoutes = [
    {
      'from'    : 'Kuala Lumpur (KUL)',
      'to'      : 'Singapore (SIN)',
      'fromCode': 'KUL',
      'toCode'  : 'SIN'
    },
    {
      'from'    : 'Kuala Lumpur (KUL)',
      'to'      : 'Bangkok (BKK)',
      'fromCode': 'KUL',
      'toCode'  : 'BKK'
    },
    {
      'from'    : 'Kuala Lumpur (KUL)',
      'to'      : 'Penang (PEN)',
      'fromCode': 'KUL',
      'toCode'  : 'PEN'
    },
    {
      'from'    : 'Johor Bahru (JHB)',
      'to'      : 'Kuala Lumpur (KUL)',
      'fromCode': 'JHB',
      'toCode'  : 'KUL'
    },
    {
      'from'    : 'Kuala Lumpur (KUL)',
      'to'      : 'Langkawi (LGK)',
      'fromCode': 'KUL',
      'toCode'  : 'LGK'
    },
    {
      'from'    : 'Kuala Lumpur (KUL)',
      'to'      : 'Bali (DPS)',
      'fromCode': 'KUL',
      'toCode'  : 'DPS'
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
                _buildHeader(),
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

  /// ────────────────────────────────────────────────────────────────
  /// HEADER
  /// ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Search Flights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                "Student Exclusive Rates",
                style: TextStyle(
                  fontSize: 12,
                  color: accentOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.school, size: 16, color: accentOrange),
                const SizedBox(width: 4),
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

  /// ────────────────────────────────────────────────────────────────
  /// CONTENT (ListView)
  /// ────────────────────────────────────────────────────────────────
  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Student fare toggle
          _buildStudentFareCard(),
          const SizedBox(height: 20),

          // Trip type selector
          _buildTripTypeSelector(),
          const SizedBox(height: 20),

          // Location fields (“From” & “To”)
          _buildLocationCard(),
          const SizedBox(height: 20),

          // Date selector
          _buildDateCard(),
          const SizedBox(height: 20),

          // Passengers & Travel Class
          _buildPassengersCard(),
          const SizedBox(height: 24),

          // Search button
          _buildSearchButton(),
          const SizedBox(height: 32),

          // Popular Routes
          _buildPopularRoutes(),
          const SizedBox(height: 32),

          // Recent searches
          _buildRecentSearches(),
        ],
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// STUDENT FARE CARD
  /// ────────────────────────────────────────────────────────────────
  Widget _buildStudentFareCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentOrange.withOpacity(0.8),
            accentOrange,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            child: const Icon(Icons.school, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Student Fare Activated",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Save up to 30% with your student ID",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
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
            activeTrackColor: Colors.white.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// TRIP TYPE (One Way / Round Trip)
  /// ────────────────────────────────────────────────────────────────
  Widget _buildTripTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : darkGrey),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// LOCATION CARD (“From” & “To” fields)
  /// ────────────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: subtleGrey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: IconButton(
                    onPressed: _swapLocations,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_vert, color: primaryColor, size: 20),
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: primaryColor),
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
                    ),
                  ),
                  const SizedBox(height: 4),
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

  /// ────────────────────────────────────────────────────────────────
  /// DATE CARD (“Departure” & optional “Return”)
  /// ────────────────────────────────────────────────────────────────
  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDateField(
            label: "Departure",
            value: _departureDate,
            onTap: () => _selectDate(true),
            icon: Icons.calendar_today,
          ),
          if (_isRoundTrip) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: subtleGrey),
            ),
            _buildDateField(
              label: "Return",
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
      displayText = DateFormat('MMM dd, yyyy').format(value);
      dayInfo = DateFormat('EEEE').format(value);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: primaryColor),
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
                    ),
                  ),
                  const SizedBox(height: 4),
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

  /// ────────────────────────────────────────────────────────────────
  /// PASSENGERS & CLASS CARD
  /// ────────────────────────────────────────────────────────────────
  Widget _buildPassengersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showPassengerSelector,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people, size: 22, color: primaryColor),
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
                      ),
                    ),
                    const SizedBox(height: 4),
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

  /// ────────────────────────────────────────────────────────────────
  /// SHOW PASSENGER & CLASS BOTTOM SHEET
  /// ────────────────────────────────────────────────────────────────
  void _showPassengerSelector() {
    final classes = ['Economy', 'Premium Economy', 'Business', 'First Class'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // so we can round the top corners
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.85,
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
                    // Drag handle
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

                    // Title
                    const Text(
                      "Passengers & Class",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Passengers counter
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
                              onPressed: _passengers > 1
                                  ? () => setState(() => _passengers--)
                                  : null,
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
                              onPressed: _passengers < 9
                                  ? () => setState(() => _passengers++)
                                  : null,
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

                    // Travel class label
                    const Text(
                      "Travel Class",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ────────────────────────────
                    // Use an Expanded ListView for class options so it can scroll if needed
                    // ────────────────────────────
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
                                // If “Economy” is selected, give it a light accentOrange highlight.
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
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? primaryColor : textColor,
                                    ),
                                  ),
                                  // If it’s Economy + student fare, show “30% OFF” badge
                                  if (_isStudentFare && className == 'Economy') ...[
                                    const Spacer(),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                    // Apply button
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

  /// ────────────────────────────────────────────────────────────────
  /// SEARCH BUTTON
  /// ────────────────────────────────────────────────────────────────
  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _searchFlights,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 22),
          const SizedBox(width: 12),
          const Text(
            "Search Flights",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_isStudentFare) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Student Rates",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// POPULAR STUDENT ROUTES
  /// ────────────────────────────────────────────────────────────────
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
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _popularRoutes.length,
            itemBuilder: (context, index) {
              final route = _popularRoutes[index];
              return Container(
                width: 160,
                margin: EdgeInsets.only(right: index < _popularRoutes.length - 1 ? 12 : 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top: “KUL → SIN” badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${route['fromCode']} → ${route['toCode']}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: accentOrange,
                            ),
                          ),
                        ),

                        // Middle: origin / icon / destination
                        Column(
                          children: [
                            Text(
                              route['fromCode']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Icon(Icons.flight_takeoff, size: 16, color: primaryColor),
                            Text(
                              route['toCode']!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),

                        // Bottom: “From RM99”
                        Text(
                          "From RM99",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// RECENT SEARCHES (Firebase)
  /// ────────────────────────────────────────────────────────────────
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
                departure : search['departure'] ?? '',
                arrival   : search['arrival'] ?? '',
                date      : DateFormat('MMM dd, yyyy').format(
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
            _arrivalCity   = arrival;
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
                          departure.split(' ')[0], // show IATA code only
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
                    _arrivalCity   = arrival;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// HELPERS, DATE PICKER, PASSENGER SELECTOR, ETC.
  /// ────────────────────────────────────────────────────────────────
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
      final temp     = _departureCity;
      _departureCity = _arrivalCity;
      _arrivalCity   = temp;
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

  /// ────────────────────────────────────────────────────────────────
  /// ON “SEARCH FLIGHTS” PRESSED
  /// ────────────────────────────────────────────────────────────────
  void _searchFlights() {
    // 1) Validate that required fields are filled:
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

    // 2) Save this search (to “recentSearches” in Firestore):
    _saveRecentSearch();

    // 3) Extract IATA codes from strings like "Kuala Lumpur (KUL)" → "KUL"
    final originCode       = _extractIata(_departureCity!);
    final destinationCode  = _extractIata(_arrivalCity!);
    final departureDateStr = DateFormat('yyyy-MM-dd').format(_departureDate!);

    // 4) Call navigator to FlightResultsPage, passing all parameters:
    Navigator.pushNamed(
      context,
      '/flight-results',
      arguments: {
        'originCode'     : originCode,
        'destinationCode': destinationCode,
        'departureDate'  : departureDateStr,
        'adults'         : _passengers,
        'travelClass'    : _selectedClass.toUpperCase(),
        'direct'         : false,
        'isStudentFare'  : _isStudentFare,
      },
    );
  }

  /// Helper to parse “Kuala Lumpur (KUL)” → "KUL"
  String _extractIata(String fullString) {
    final match = RegExp(r'\((\w{3})\)').firstMatch(fullString);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }
    return fullString; // fallback if no parentheses
  }

  Future<void> _saveRecentSearch() async {
    try {
      await _firestore.collection('recentSearches').add({
        'userId'    : _auth.currentUser?.uid,
        'departure' : _departureCity,
        'arrival'   : _arrivalCity,
        'date'      : _departureDate,
        'passengers': '$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'}',
        'timestamp' : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving recent search: $e');
    }
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
/// Dotted Pattern Painter (unchanged)
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