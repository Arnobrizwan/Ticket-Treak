// lib/screens/user/flight/flight_detail_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FlightDetailScreen extends StatefulWidget {
  const FlightDetailScreen({Key? key}) : super(key: key);

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen>
    with TickerProviderStateMixin {
  // Violin color palette (matching OnboardingScreen) - STRICTLY FOLLOWING
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
  static const Color textColor = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E); // Muted Brown
  static const Color successColor =
      Color(0xFF8B5000); // Success (using secondary)
  static const Color warningColor = Color(0xFFD4A373); // Warning (using accent)

  // Flight data fields
  Map<String, dynamic>? _offer;
  String? _originCode;
  String? _destinationCode;
  String? _departureDateStr;
  int? _adults;
  String? _travelClass;
  bool? _direct;
  bool? _isStudentFare;

  bool _didFetchArgs = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _alreadySaved = false;
  String? _errorMessage;

  // Animation controllers
  late final AnimationController _slideController;
  late final AnimationController _fadeController;
  late final AnimationController _saveController;
  late final AnimationController _pulseController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _saveAnimation;
  late Animation<double> _pulseAnimation;

  // Common currency symbols map
  final Map<String, String> _currencySymbols = {
    'MYR': 'RM',
    'USD': '\$',
    'EUR': '€',
    'SGD': 'S\$',
    'THB': '฿',
    'IDR': 'Rp',
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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
    _saveController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _saveAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the pulsing "loading" circle
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _saveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Fetch passed‐in arguments exactly once
    if (!_didFetchArgs) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args == null) {
          setState(() {
            _errorMessage = "No flight data provided";
            _isLoading = false;
          });
          return;
        }
        final argsMap = args as Map<String, dynamic>;
        _offer = argsMap['offer'] as Map<String, dynamic>?;
        _originCode = argsMap['originCode'] as String?;
        _destinationCode = argsMap['destinationCode'] as String?;
        _departureDateStr = argsMap['departureDate'] as String?;
        _adults = argsMap['adults'] as int?;
        _travelClass = argsMap['travelClass'] as String?;
        _direct = argsMap['direct'] as bool?;
        _isStudentFare = argsMap['isStudentFare'] as bool?;
        if (_offer == null) {
          setState(() {
            _errorMessage = "Invalid flight data";
            _isLoading = false;
          });
          return;
        }
        _didFetchArgs = true;
        _loadFlightData();
      } catch (e) {
        setState(() {
          _errorMessage = "Error loading flight data: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFlightData() async {
    try {
      await _checkIfAlreadySaved();
      setState(() => _isLoading = false);
      _slideController.forward();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading flight details: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfAlreadySaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _offer == null) return;
    try {
      final offerId = _offer!['id']?.toString() ?? '';
      if (offerId.isEmpty) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('savedFlights')
          .where('userId', isEqualTo: userId)
          .where('offerId', isEqualTo: offerId)
          .get();
      if (mounted) {
        setState(() {
          _alreadySaved = snapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking saved flights: $e');
    }
  }

  Future<void> _saveCurrentOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in to save flights', isError: true);
      return;
    }
    if (_offer == null) {
      _showMessage('No flight data to save', isError: true);
      return;
    }
    _saveController.forward().then((_) => _saveController.reverse());
    setState(() => _isSaving = true);
    try {
      final offerId = _offer!['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance.collection('savedFlights').add({
        'userId': user.uid,
        'offerId': offerId,
        'rawOfferJson': _offer!,
        'originCode': _originCode ?? '',
        'destinationCode': _destinationCode ?? '',
        'departureDateStr': _departureDateStr ?? '',
        'adults': _adults ?? 1,
        'travelClass': _travelClass ?? '',
        'direct': _direct ?? false,
        'isStudentFare': _isStudentFare ?? false,
        'savedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _isSaving = false;
        _alreadySaved = true;
      });
      _showMessage('Flight saved successfully! ✈️');
      // → Once saved, navigate to “Saved Flights” page so the user can see / delete their previous saves
      Navigator.pushNamed(context, '/saved-flights');
    } catch (e) {
      setState(() => _isSaving = false);
      _showMessage('Error saving flight: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildModernAppBar(),
      body: SafeArea(child: _buildBody()),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            "Flight Details",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/flight-search', (route) => false);
            }
          },
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: _shareFlightDetails,
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildEnhancedLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    if (_offer == null) {
      return _buildErrorState(errorText: "No flight data available");
    }
    return _buildContent();
  }

  Widget _buildEnhancedLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.flight, color: Colors.white, size: 40),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Loading flight details...",
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Please wait a moment",
            style: TextStyle(
              fontSize: 14,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({String? errorText}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  size: 64, color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            const Text(
              "Unable to load flight details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorText ?? _errorMessage ?? "Please try again",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: darkGrey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/flight-search', (route) => false);
                }
              },
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("Go Back"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    try {
      final priceInfo = _offer!['price'] as Map<String, dynamic>;
      final totalPrice = priceInfo['total'] as String;
      final currency = priceInfo['currency'] as String;
      final itineraries = _offer!['itineraries'] as List<dynamic>;

      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildEnhancedFlightHeader(currency, totalPrice),
                  ),
                );
              },
            ),
          ),
          _buildEnhancedFlightDetails(itineraries),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildEnhancedActionButtons(),
                );
              },
            ),
          ),
        ],
      );
    } catch (e) {
      return _buildErrorState(errorText: "Error parsing flight data: $e");
    }
  }

  ///
  /// Replace the plain‐text carrier code box with a Network Image (pics.avs.io).
  /// If the logo fails to load, we fall back to showing the two‐letter code in a colored container.
  ///
  Widget _buildEnhancedFlightHeader(String currency, String totalPrice) {
    // Grab the carrier code (e.g. "OD") and map its color/name:
    final carrierCode = _getMainCarrierCode(); // e.g. "OD"
    final airlineColor = _getAirlineColor(carrierCode); // lookup map for colors
    final airlineName = _getAirlineName(carrierCode); // e.g. 'Batik Air'

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top gradient header ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  airlineColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT COLUMN: route/date + three chips ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1) Route (e.g. "KUL → PEN")
                      Row(
                        children: [
                          Text(
                            _originCode ?? 'N/A',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: airlineColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.flight_takeoff,
                              color: airlineColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _destinationCode ?? 'N/A',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: airlineColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      // 2) Departure date line
                      Text(
                        _departureDateStr != null
                            ? DateFormat('EEEE, MMM dd, yyyy')
                                .format(DateTime.parse(_departureDateStr!))
                            : 'Date not available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 12),
                      // 3) Three info chips (passenger, class, airline name) on one line
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          _buildInfoChip(
                            Icons.people,
                            "${_adults ?? 1} passenger${(_adults ?? 1) > 1 ? 's' : ''}",
                            primaryColor,
                          ),
                          _buildInfoChip(
                            Icons.business_center,
                            (_travelClass ?? 'economy').toLowerCase(),
                            secondaryColor,
                          ),
                          _buildInfoChip(
                            Icons.flight,
                            airlineName,
                            airlineColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── RIGHT COLUMN: NEW BANNER + price / student badge / logo ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ◀── INSERTED BANNER ◀───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentOrange, // accent color for the banner
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "SPECIAL OFFER", // change this text as needed
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 1) Price (e.g. “RM 164.28”)
                    Text(
                      "${_currencySymbols[currency] ?? currency} $totalPrice",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 2) “STUDENT FARE” badge (only if applicable)
                    if (_isStudentFare == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "STUDENT FARE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 3) Airline logo (pics.avs.io). Falls back to colored box + code if it fails.
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://pics.avs.io/100/100/$carrierCode.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // fallback: show two-letter code on colored background
                            return Container(
                              color: airlineColor,
                              alignment: Alignment.center,
                              child: Text(
                                carrierCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFlightDetails(List<dynamic> itineraries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, itinIndex) {
          try {
            final singleItin = itineraries[itinIndex] as Map<String, dynamic>;
            final durationStr = singleItin['duration'] as String? ?? 'N/A';
            final segments = singleItin['segments'] as List<dynamic>? ?? [];

            return AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset:
                      Offset(0, 20 * _slideAnimation.value * (itinIndex + 1)),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Journey header
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itineraries.length > 1
                                      ? "Journey ${itinIndex + 1}"
                                      : "Flight Journey",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule,
                                          size: 14, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(durationStr),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Segments
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children:
                                  List.generate(segments.length, (segIndex) {
                                return _buildEnhancedSegmentCard(
                                    segments[segIndex],
                                    segIndex,
                                    segments.length);
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } catch (e) {
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Error loading journey ${itinIndex + 1}: $e",
                style: TextStyle(color: Colors.red.shade700),
              ),
            );
          }
        },
        childCount: itineraries.length,
      ),
    );
  }

  Widget _buildEnhancedSegmentCard(
      Map<String, dynamic> seg, int segIndex, int totalSegments) {
    try {
      final dep = seg['departure'] as Map<String, dynamic>? ?? {};
      final arr = seg['arrival'] as Map<String, dynamic>? ?? {};
      final carrier = seg['carrierCode'] as String? ?? 'N/A';
      final flightNo = seg['number'] as String? ?? 'N/A';

      final depAtStr = dep['at'] as String?;
      final arrAtStr = arr['at'] as String?;

      if (depAtStr == null || arrAtStr == null) {
        return _buildSegmentError("Invalid segment timing data");
      }

      final depAt = DateTime.parse(depAtStr);
      final arrAt = DateTime.parse(arrAtStr);

      final depTimeFmt = DateFormat('HH:mm').format(depAt);
      final depDateFmt = DateFormat('MMM dd').format(depAt);
      final arrTimeFmt = DateFormat('HH:mm').format(arrAt);
      final arrDateFmt = DateFormat('MMM dd').format(arrAt);

      final duration = arrAt.difference(depAt);
      final durationStr = "${duration.inHours}h ${duration.inMinutes % 60}m";
      final airlineColor = _getAirlineColor(carrier);

      return Column(
        children: [
          Container(
            margin:
                EdgeInsets.only(bottom: segIndex < totalSegments - 1 ? 16 : 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  backgroundColor.withOpacity(0.25),
                  airlineColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: airlineColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Airline header (with logo)
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          "https://pics.avs.io/100/100/$carrier.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // fallback to two‐letter code
                            return Container(
                              color: airlineColor,
                              alignment: Alignment.center,
                              child: Text(
                                carrier,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAirlineName(carrier),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Flight $carrier $flightNo",
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: airlineColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Duration: $durationStr",
                              style: TextStyle(
                                fontSize: 10,
                                color: airlineColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Segment ${segIndex + 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Flight path with enhanced design
                Row(
                  children: [
                    // Departure
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            depTimeFmt,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dep['iataCode'] as String? ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            depDateFmt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                          if (dep['terminal'] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Terminal ${dep['terminal']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Enhanced flight path
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: airlineColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [airlineColor, primaryColor],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: airlineColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: airlineColor.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.flight,
                                    color: Colors.white, size: 16),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryColor, airlineColor],
                                    ),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: airlineColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            durationStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrival
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            arrTimeFmt,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            arr['iataCode'] as String? ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            arrDateFmt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                          if (arr['terminal'] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Terminal ${arr['terminal']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: accentOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Layover indicator
          if (segIndex < totalSegments - 1) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 18, color: warningColor),
                  const SizedBox(width: 6),
                  Text(
                    "Layover in ${arr['iataCode'] ?? 'N/A'}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: warningColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    } catch (e) {
      return _buildSegmentError("Error loading segment: $e");
    }
  }

  Widget _buildSegmentError(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Save flight button ──
          AnimatedBuilder(
            animation: _saveAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _saveAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _alreadySaved
                        ? LinearGradient(
                            colors: [darkGrey, darkGrey.withOpacity(0.8)])
                        : const LinearGradient(
                            colors: [primaryColor, secondaryColor]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_alreadySaved ? darkGrey : primaryColor)
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        (_alreadySaved || _isSaving) ? null : _saveCurrentOffer,
                    icon: Icon(
                      _alreadySaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      _alreadySaved
                          ? "Flight Saved ✓"
                          : (_isSaving ? "Saving..." : "Save Flight"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // ── Secondary action buttons ──
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _shareFlightDetails,
                    icon:
                        const Icon(Icons.share, color: primaryColor, size: 18),
                    label: const Text(
                      "Share",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [successColor, accentGreen]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: successColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/seat-selection',
                        arguments: {
                          'offer': _offer,
                          'originCode': _originCode,
                          'destinationCode': _destinationCode,
                          'departureDate': _departureDateStr,
                          'adults': _adults,
                          'travelClass': _travelClass,
                          'direct': _direct,
                          'isStudentFare': _isStudentFare,
                        },
                      );
                    },
                    icon: const Icon(Icons.flight_takeoff,
                        color: Colors.white, size: 20),
                    label: const Text(
                      "Book Now",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Convert ISO8601 duration (e.g. "PT2H30M") to "2h 30m"
  String _formatDuration(String isoDuration) {
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours = match.group(1)!;
      final minutes = match.group(2)!;
      return "${hours}h ${minutes}m";
    }
    return isoDuration
        .replaceFirst("PT", "")
        .replaceAll("H", "h ")
        .replaceAll("M", "m");
  }

  // Get the carrier code from the first segment (uppercase)
  String _getMainCarrierCode() {
    try {
      final itineraries = _offer!['itineraries'] as List<dynamic>;
      final firstItin = itineraries[0] as Map<String, dynamic>;
      final segments = firstItin['segments'] as List<dynamic>;
      final firstSeg = segments[0] as Map<String, dynamic>;
      return (firstSeg['carrierCode'] as String?)?.toUpperCase() ?? 'XX';
    } catch (e) {
      return 'XX';
    }
  }

  // Airline‐specific brand colors (including OD → Batik Air)
  Color _getAirlineColor(String carrier) {
    final colors = {
      'MH': const Color(0xFF5C2E00), // Malaysia Airlines - Brown
      'AK': const Color(0xFFDC2626), // AirAsia          - Red
      'SQ': const Color(0xFF8B5000), // Singapore Airlines - Amber Brown
      'TG': const Color(0xFF7C2D92), // Thai Airways     - Purple
      'GA': const Color(0xFFB28F5E), // Garuda Indonesia - Muted Brown
      'EK': const Color(0xFFB91C1C), // Emirates         - Dark Red
      'OD': const Color(0xFFE53935), // Batik Air        - Crimson-ish
    };
    return colors[carrier] ?? primaryColor;
  }

  // Airline display names (including OD → Batik Air)
  String _getAirlineName(String code) {
    final airlines = {
      'MH': 'Malaysia Airlines',
      'AK': 'AirAsia',
      'SQ': 'Singapore Airlines',
      'TG': 'Thai Airways',
      'GA': 'Garuda Indonesia',
      'EK': 'Emirates',
      'OD': 'Batik Air',
    };
    return airlines[code] ?? 'Airline $code';
  }

  void _copyOfferIdToClipboard() {
    final offerId = _offer?['id']?.toString() ?? '';
    if (offerId.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: offerId));
      _showMessage('Booking reference copied to clipboard! 📋');
    }
  }

  void _shareFlightDetails() {
    final flightInfo =
        "${_originCode ?? 'N/A'} → ${_destinationCode ?? 'N/A'} on ${_departureDateStr ?? 'N/A'}";
    _showMessage('Sharing: $flightInfo ✈️');
  }

  void _proceedToBooking() {
    _showMessage('Redirecting to booking platform... 🎫');
  }
}
