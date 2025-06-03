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
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange    = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown
  static const Color successColor    = Color(0xFF8B5000);  // Success (using secondary)
  static const Color warningColor    = Color(0xFFD4A373);  // Warning (using accent)

  // Form data
  final _formKey = GlobalKey<FormState>();
  String?   _departureCity;
  String?   _arrivalCity;
  DateTime? _departureDate;
  DateTime? _returnDate;
  int       _passengers     = 1;
  String    _selectedClass  = 'Economy';
  String    _selectedSeatType = 'Standard';
  bool      _isRoundTrip    = false;
  bool      _isStudentFare  = true;
  bool      _isFlexibleDates = false;
  bool      _needsHotel     = false;
  bool      _needsTransport = false;

  // Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth      _auth      = FirebaseAuth.instance;

  // Animation
  late AnimationController _animationController;
  late Animation<double>   _fadeAnimation;
  late AnimationController _searchButtonController;
  late Animation<double>   _searchButtonScale;
  late AnimationController _cardController;
  late Animation<double>   _cardAnimation;

  // Enhanced popular routes with high-quality Unsplash travel images
  final List<Map<String, dynamic>> _popularRoutes = [
    {
      'from':      'Kuala Lumpur (KUL)',
      'to':        'Singapore (SIN)',
      'fromCode':  'KUL',
      'toCode':    'SIN',
      'duration':  '1h 20m',
      'airlines':  ['Malaysia Airlines', 'AirAsia'],
      'price':     189,
      'discount':  30,
      'imageUrl':  'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80'
    },
    {
      'from':      'Kuala Lumpur (KUL)',
      'to':        'Bangkok (BKK)',
      'fromCode':  'KUL',
      'toCode':    'BKK',
      'duration':  '2h 5m',
      'airlines':  ['Thai Airways', 'AirAsia'],
      'price':     299,
      'discount':  25,
      'imageUrl':  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
    },
    {
      'from':      'Kuala Lumpur (KUL)',
      'to':        'Bali (DPS)',
      'fromCode':  'KUL',
      'toCode':    'DPS',
      'duration':  '3h 15m',
      'airlines':  ['Malaysia Airlines', 'Garuda'],
      'price':     459,
      'discount':  35,
      'imageUrl':  'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
    },
    {
      'from':      'Johor Bahru (JHB)',
      'to':        'Kuala Lumpur (KUL)',
      'fromCode':  'JHB',
      'toCode':    'KUL',
      'duration':  '1h 15m',
      'airlines':  ['Malaysia Airlines', 'AirAsia'],
      'price':     129,
      'discount':  20,
      'imageUrl':  'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800&q=80',
    },
    {
      'from':      'Kuala Lumpur (KUL)',
      'to':        'Penang (PEN)',
      'fromCode':  'KUL',
      'toCode':    'PEN',
      'duration':  '1h 30m',
      'airlines':  ['Malaysia Airlines', 'AirAsia'],
      'price':     159,
      'discount':  25,
      'imageUrl':  'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&q=80',
    },
    {
      'from':      'Kuala Lumpur (KUL)',
      'to':        'Langkawi (LGK)',
      'fromCode':  'KUL',
      'toCode':    'LGK',
      'duration':  '1h 45m',
      'airlines':  ['Malaysia Airlines', 'AirAsia'],
      'price':     199,
      'discount':  30,
      'imageUrl':  'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _searchButtonController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _searchButtonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _searchButtonController, curve: Curves.easeInOut),
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _cardController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchButtonController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Modern background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: ModernPatternPainter(color: primaryColor.withOpacity(0.03)),
            ),
          ),

          CustomScrollView(
            slivers: [
              _buildModernAppBar(),
              SliverToBoxAdapter(
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
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Search Flights",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        if (_isStudentFare)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentOrange,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: accentOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                const Text(
                  "30% OFF",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: Padding(
        // Trimmed outer padding from 20→16
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentFareCard(),
            const SizedBox(height: 16),
            _buildTripTypeSelector(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildDateCard(),
            const SizedBox(height: 16),
            _buildPassengersAndClassCard(),
            const SizedBox(height: 16),
            _buildAdditionalServicesCard(),
            const SizedBox(height: 16),
            _buildFlexibleDatesOption(),
            const SizedBox(height: 24),
            _buildEnhancedSearchButton(),
            const SizedBox(height: 24),
            _buildPopularRoutes(),
            const SizedBox(height: 24),
            _buildRecentSearches(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentFareCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16), // trimmed from 24→16
      decoration: BoxDecoration(
        gradient: _isStudentFare
            ? const LinearGradient(
                colors: [successColor, accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(colors: [subtleGrey, subtleGrey]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isStudentFare ? successColor : subtleGrey).withOpacity(0.3),
            blurRadius: 16, // slightly smaller blur
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12), // from 16→12
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isStudentFare ? Icons.school : Icons.school_outlined,
              color: Colors.white,
              size: 28, // trimmed from 32→28
            ),
          ),
          const SizedBox(width: 16), // was 20→16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isStudentFare ? "Student Fare Activated" : "Enable Student Discount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // trimmed 20→18
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4), // trimmed 6→4
                Text(
                  _isStudentFare
                      ? "Save up to 30% with your student ID"
                      : "Verify student status to save money",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14, // trimmed 15→14
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20, // trimmed from 25→20
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
        padding: const EdgeInsets.symmetric(vertical: 16), // from 18→16
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryColor, secondaryColor])
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : darkGrey), // from 22→20
            const SizedBox(width: 8), // from 12→8
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14, // from 16→14
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 16), // from 24→16
            child: Row(
              children: [
                const Expanded(child: Divider(color: subtleGrey, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12), // from 16→12
                  child: GestureDetector(
                    onTap: _swapLocations,
                    child: Container(
                      padding: const EdgeInsets.all(10), // from 12→10
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryColor, secondaryColor]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert, color: Colors.white, size: 18), // from 20→18
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: subtleGrey, thickness: 1)),
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
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16), // from 24→16
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), // from 14→12
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: primaryColor), // from 26→24
            ),
            const SizedBox(width: 16), // from 20→16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12, // from 13→12
                      color: darkGrey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4), // trimmed from 8→4
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 15, // from 17→15
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      color: value != null ? textColor : darkGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: darkGrey), // from 16→14
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: subtleGrey, thickness: 1),
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
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(16), // from 24→16
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), // from 14→12
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: primaryColor), // from 26→24
            ),
            const SizedBox(width: 16), // from 20→16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12, // from 13→12
                      color: darkGrey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 15, // from 17→15
                      fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
                      color: value != null ? textColor : darkGrey,
                    ),
                  ),
                  if (dayInfo != null)
                    Text(
                      dayInfo,
                      style: TextStyle(
                        fontSize: 12, // from 13→12
                        color: accentOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: darkGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengersAndClassCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showPassengerSelector,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16), // from 24→16
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), // from 14→12
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.people, size: 24, color: primaryColor), // from 26→24
              ),
              const SizedBox(width: 16), // from 20→16
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Passengers & Class",
                      style: TextStyle(
                        fontSize: 12, // from 13→12
                        color: darkGrey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'} • $_selectedClass",
                      style: const TextStyle(
                        fontSize: 15, // from 17→15
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: darkGrey),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_business, size: 18, color: primaryColor), // from 20→18
            ),
            const SizedBox(width: 8), // from 12→8
            const Text(
              "Additional Services",
              style: TextStyle(
                fontSize: 18, // from 20→18
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // from 20→12

        // Hotel booking option
        Container(
          margin: const EdgeInsets.only(bottom: 12), // from bottom 16→12
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12, // from 15→12
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16), // from 20→16
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // from 12→10
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentOrange.withOpacity(0.1), accentOrange.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.hotel, color: accentOrange, size: 22), // from 24→22
                ),
                const SizedBox(width: 12), // from 16→12
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Hotel Booking",
                        style: TextStyle(
                          fontSize: 15, // from 16→15
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2), // from 4→2
                      Text(
                        "Save up to 25% on hotel stays",
                        style: TextStyle(
                          fontSize: 12, // from 13→12
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16), // from 20→16
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // from 12→10
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentGreen.withOpacity(0.1), accentGreen.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car, color: accentGreen, size: 22), // from 24→22
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Ground Transport",
                        style: TextStyle(
                          fontSize: 15, // from 16→15
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Airport transfers & car rentals",
                        style: TextStyle(
                          fontSize: 12, // from 13→12
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
          const SizedBox(height: 12), // trimmed from 16→12
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentOrange.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                // Navigate to seat selection page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.airline_seat_recline_extra, color: Colors.white),
                        const SizedBox(width: 12),
                        Text('Navigating to seat selection for $_selectedClass'),
                      ],
                    ),
                    backgroundColor: accentOrange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16), // from 20→16
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), // from 12→10
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentOrange.withOpacity(0.1), accentOrange.withOpacity(0.2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.airline_seat_recline_extra, color: accentOrange, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Your $_selectedClass Seat",
                            style: const TextStyle(
                              fontSize: 15, // from 16→15
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Choose your preferred seat location",
                            style: TextStyle(
                              fontSize: 12, // from 13→12
                              color: darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [accentOrange, warningColor]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Select",
                        style: TextStyle(
                          fontSize: 12, // trimmed from 13→12
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20, // from 25→20
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16), // from 24→16
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // from 12→10
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.date_range, color: primaryColor, size: 22), // from 24→22
            ),
            const SizedBox(width: 16), // from 20→16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Flexible Dates",
                    style: TextStyle(
                      fontSize: 15, // from 17→15
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Find cheaper flights ±3 days",
                    style: TextStyle(
                      fontSize: 12, // from 13→12
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
            height: 56, // trimmed height from 64→56
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 16, // from 20→16
                  offset: const Offset(0, 8), // from 0,10→0,8
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
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 24, color: Colors.white), // from 26→24
                  const SizedBox(width: 12), // from 16→12
                  const Text(
                    "Search Flights",
                    style: TextStyle(
                      fontSize: 17, // from 19→17
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
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Student Rates",
                        style: TextStyle(
                          fontSize: 12, // from 13→12
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Make each card around 75% of screen width, up to a max of 300
    final cardWidth = (screenWidth * 0.75).clamp(240.0, 300.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.trending_up, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 12),
            const Text(
              "Popular Student Routes",
              style: TextStyle(
                fontSize: 18, // trimmed from 20→18
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // trimmed from 20→16

        // ⬇️ Parent height = 220px (unchanged) ⬇️
        SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _popularRoutes.length,
                itemBuilder: (context, index) {
                  final route = _popularRoutes[index];
                  return Transform.translate(
                    offset: Offset(20 * (1 - _cardAnimation.value), 0),
                    child: Opacity(
                      opacity: _cardAnimation.value,
                      child: Container(
                        width: cardWidth, // now relative instead of fixed 280
                        margin: EdgeInsets.only(
                          right: index < _popularRoutes.length - 1 ? 16 : 0, // from 20→16
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20, // from 25→20
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _departureCity = route['from'];
                              _arrivalCity   = route['to'];
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              // ── HEADER IMAGE (100px tall) ──
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor.withOpacity(0.8),
                                      secondaryColor.withOpacity(0.6),
                                    ],
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(route['imageUrl'] as String),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withOpacity(0.3),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Discount badge (top-right)
                                    Positioned(
                                      top: 8, // trimmed from 12→8
                                      right: 8, // trimmed from 12→8
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6, // from 8→6
                                          vertical: 3,  // from 4→3
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [accentOrange, warningColor],
                                          ),
                                          borderRadius: BorderRadius.circular(14), // slightly smaller
                                        ),
                                        child: Text(
                                          "${route['discount']}% OFF",
                                          style: const TextStyle(
                                            fontSize: 10, // from 12→10
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Centered route codes + duration
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${route['fromCode']} → ${route['toCode']}",
                                            style: const TextStyle(
                                              fontSize: 16, // from 18→16
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8, // from 10→8
                                              vertical: 3,    // from 4→3
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              route['duration'] as String,
                                              style: TextStyle(
                                                fontSize: 12, // from 14→12
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── CONTENT SECTION (remaining 120px) ──
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12), // from 20→12
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // a) Price row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "From",
                                                style: TextStyle(
                                                  fontSize: 12, // stays 12
                                                  color: darkGrey,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "RM${route['price']}",
                                                style: TextStyle(
                                                  fontSize: 18, // from 20→18
                                                  fontWeight: FontWeight.bold,
                                                  color: successColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  primaryColor.withOpacity(0.1),
                                                  secondaryColor.withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.flight_takeoff,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),

                                      // b) Airlines text
                                      Text(
                                        (route['airlines'] as List<String>).join(" • "),
                                        style: TextStyle(
                                          fontSize: 12, // from 13→12
                                          color: darkGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// ──────────────────────────────────────────────────────
  /// FIXED PASSENGER & CLASS SELECTOR
  /// ──────────────────────────────────────────────────────
  void _showPassengerSelector() {
    final classes = ['Economy', 'Premium Economy', 'Business', 'First Class'];

    // Local copies for the modal
    int    tempPassengers    = _passengers;
    String tempSelectedClass = _selectedClass;

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // from 20→16
                child: StatefulBuilder(
                  builder: (context, setLocalState) {
                    return Column(
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
                            fontSize: 18, // from 20→18
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 12), // from 16→12

                        // Passenger count row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Passengers",
                              style: TextStyle(
                                fontSize: 14, // from 16→14
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: tempPassengers > 1
                                      ? () {
                                          setLocalState(() => tempPassengers--);
                                        }
                                      : null,
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: tempPassengers > 1
                                          ? primaryColor.withOpacity(0.1)
                                          : subtleGrey.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 18,
                                      color: tempPassengers > 1 ? primaryColor : darkGrey,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12), // from 16→12
                                  child: Text(
                                    tempPassengers.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: tempPassengers < 9
                                      ? () {
                                          setLocalState(() => tempPassengers++);
                                        }
                                      : null,
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: tempPassengers < 9
                                          ? primaryColor.withOpacity(0.1)
                                          : subtleGrey.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 18,
                                      color: tempPassengers < 9 ? primaryColor : darkGrey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12), // from 16→12

                        // Travel class selection list
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
                              final isSelected = tempSelectedClass == className;
                              return GestureDetector(
                                onTap: () {
                                  setLocalState(() {
                                    tempSelectedClass = className;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12), // from 16→12
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
                                          fontSize: 14, // from 16→14
                                          fontWeight:
                                              isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? primaryColor : textColor,
                                        ),
                                      ),
                                      if (_isStudentFare && className == 'Economy') ...[
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: accentOrange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "30% OFF",
                                            style: TextStyle(
                                              fontSize: 11, // from 12→11
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

                        const SizedBox(height: 8),
                        // Apply button commits local changes to outer state
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _passengers     = tempPassengers;
                                _selectedClass  = tempSelectedClass;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14), // from 16→14
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
                      ],
                    );
                  },
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
              padding: const EdgeInsets.all(16), // from 20→16
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
                  const SizedBox(height: 16), // from 20→16
                  Text(
                    isDeparture ? "Select Departure" : "Select Destination",
                    style: const TextStyle(
                      fontSize: 18, // from 20→18
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12), // from 16→12
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
                  const SizedBox(height: 12), // from 20→12
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
                          padding: EdgeInsets.symmetric(vertical: 12),
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
        style: const TextStyle(
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

  String _mapTravelClass(String selectedClass) {
    switch (selectedClass.toUpperCase()) {
      case 'ECONOMY':
        return 'ECONOMY';
      case 'PREMIUM ECONOMY':
        return 'PREMIUM_ECONOMY';
      case 'BUSINESS':
        return 'BUSINESS';
      case 'FIRST CLASS':
        return 'FIRST';
      default:
        return 'ECONOMY';
    }
  }

  void _searchFlights() {
    if (_departureCity == null || _arrivalCity == null || _departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please fill in all required fields'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_isRoundTrip && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please select a return date'),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    _saveRecentSearch();

    final originCode      = _extractIata(_departureCity!);
    final destinationCode = _extractIata(_arrivalCity!);
    final departureDateStr = DateFormat('yyyy-MM-dd').format(_departureDate!);

    Navigator.pushNamed(
      context,
      '/flight-results',
      arguments: {
        'originCode':      originCode,
        'destinationCode': destinationCode,
        'departureDate':   departureDateStr,
        'adults':          _passengers,
        'travelClass':     _mapTravelClass(_selectedClass),
        'direct':          false,
        'isStudentFare':   _isStudentFare,
        'needsHotel':      _needsHotel,
        'needsTransport':  _needsTransport,
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
        'userId':     _auth.currentUser?.uid,
        'departure':  _departureCity,
        'arrival':    _arrivalCity,
        'date':       _departureDate,
        'passengers': '$_passengers ${_passengers == 1 ? 'Passenger' : 'Passengers'}',
        'timestamp':  FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving recent search: $e');
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.history, size: 20, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Recent Searches",
                      style: TextStyle(
                        fontSize: 18, // trimmed from 20→18
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
            const SizedBox(height: 12), // trimmed from 16→12
            ...snapshot.data!.docs.map((doc) {
              final search = doc.data() as Map<String, dynamic>;
              return _buildRecentSearchItem(
                departure: search['departure'] ?? '',
                arrival:   search['arrival'] ?? '',
                date:      DateFormat('MMM dd, yyyy').format(
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12, // from 15→12
            offset: const Offset(0, 4),
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12), // from 16→12
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: subtleGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history, color: darkGrey, size: 18), // from 20→18
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
                    const SizedBox(height: 2),
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

  Future<void> _clearRecentSearches() async {
    try {
      final batch    = _firestore.batch();
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
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Recent searches cleared'),
            ],
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }
}

/// ────────────────────────────────────────────────────────────────
/// Modern Pattern Painter
/// ────────────────────────────────────────────────────────────────
class ModernPatternPainter extends CustomPainter {
  final Color color;
  ModernPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;

    // Create a modern geometric pattern
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        if ((x + y) % 80 == 0) {
          // Draw small circles
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
        if ((x - y) % 120 == 0) {
          // Draw diamond shapes
          final path = Path();
          path.moveTo(x, y - 3);
          path.lineTo(x + 3, y);
          path.lineTo(x, y + 3);
          path.lineTo(x - 3, y);
          path.close();
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}