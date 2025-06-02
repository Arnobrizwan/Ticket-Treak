// lib/screens/user/flight/flight_detail_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightDetailScreen extends StatefulWidget {
  const FlightDetailScreen({Key? key}) : super(key: key);

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> with TickerProviderStateMixin {
  // Violin color palette (same as FlightSearchPage and FlightResultsPage)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor = Color(0xFF5C2E00);     // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000);   // Amber Brown
  static const Color textColor = Color(0xFF35281E);        // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7);       // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C);         // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373);     // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E);      // Muted Brown

  late final Map<String, dynamic> _offer;
  late final String _originCode;
  late final String _destinationCode;
  late final String _departureDateStr;
  late final int _adults;
  late final String _travelClass;
  late final bool _direct;
  late final bool _isStudentFare;
  
  bool _isSaving = false;
  bool _alreadySaved = false;
  bool _isLoading = true;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _saveController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _saveAnimation;

  // Airline logos mapping
  final Map<String, String> _airlineLogos = {
    'MH': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
    'AK': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
    'SQ': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
    'TG': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
    'GA': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
    'EK': 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
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

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _saveAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _saveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _offer = args['offer'] as Map<String, dynamic>;
    _originCode = args['originCode'] as String;
    _destinationCode = args['destinationCode'] as String;
    _departureDateStr = args['departureDate'] as String;
    _adults = args['adults'] as int;
    _travelClass = args['travelClass'] as String;
    _direct = args['direct'] as bool;
    _isStudentFare = args['isStudentFare'] as bool;
    
    _loadFlightData();
  }

  Future<void> _loadFlightData() async {
    await _checkIfAlreadySaved();
    
    setState(() {
      _isLoading = false;
    });
    
    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _checkIfAlreadySaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('savedFlights')
          .where('userId', isEqualTo: userId)
          .where('offerId', isEqualTo: _offer['id'])
          .get();

      setState(() {
        _alreadySaved = snapshot.docs.isNotEmpty;
      });
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

    _saveController.forward().then((_) => _saveController.reverse());
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('savedFlights').add({
        'userId': user.uid,
        'offerId': _offer['id'],
        'rawOfferJson': _offer,
        'originCode': _originCode,
        'destinationCode': _destinationCode,
        'departureDateStr': _departureDateStr,
        'adults': _adults,
        'travelClass': _travelClass,
        'direct': _direct,
        'isStudentFare': _isStudentFare,
        'savedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaving = false;
        _alreadySaved = true;
      });

      _showMessage('Flight saved successfully!');
    } catch (e) {
      setState(() => _isSaving = false);
      _showMessage('Error saving flight: $e', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : accentGreen,
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(),
        body: _buildLoadingState(),
      );
    }

    final priceInfo = _offer['price'] as Map<String, dynamic>;
    final totalPrice = priceInfo['total'] as String;
    final currency = priceInfo['currency'] as String;
    final itineraries = _offer['itineraries'] as List<dynamic>;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFlightHeader(currency, totalPrice),
                  ),
                );
              },
            ),
          ),
          _buildFlightDetails(itineraries),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildActionButtons(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      title: Text(
        "Flight Details",
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareFlightDetails,
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 4,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: const Icon(Icons.flight, color: Colors.white, size: 24),
            ),
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
        ],
      ),
    );
  }

  Widget _buildFlightHeader(String currency, String totalPrice) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.1), accentOrange.withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$_originCode → $_destinationCode",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(
                            DateTime.parse(_departureDateStr),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: darkGrey,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$currency $totalPrice",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: accentGreen,
                          ),
                        ),
                        if (_isStudentFare)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentGreen,
                              borderRadius: BorderRadius.circular(8),
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoChip(Icons.people, "$_adults passenger${_adults > 1 ? 's' : ''}"),
                    const SizedBox(width: 12),
                    _buildInfoChip(Icons.business_center, _travelClass.toLowerCase()),
                    const SizedBox(width: 12),
                    if (_direct)
                      _buildInfoChip(Icons.trending_flat, "Direct", color: accentGreen),
                  ],
                ),
              ],
            ),
          ),
          
          // Offer ID section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.confirmation_number, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Booking Reference:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _offer['id'].toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: darkGrey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copyOfferIdToClipboard,
                  icon: Icon(Icons.copy, color: primaryColor, size: 18),
                  tooltip: "Copy reference",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? primaryColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightDetails(List<dynamic> itineraries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, itinIndex) {
          final singleItin = itineraries[itinIndex] as Map<String, dynamic>;
          final durationStr = singleItin['duration'] as String;
          final segments = singleItin['segments'] as List<dynamic>;

          return AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * _slideAnimation.value * (itinIndex + 1)),
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
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Itinerary header
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
                                    : "Flight Details",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 18, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatDuration(durationStr),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Segments
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: List.generate(segments.length, (segIndex) {
                              return _buildSegmentCard(segments[segIndex], segIndex, segments.length);
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
        },
        childCount: itineraries.length,
      ),
    );
  }

  Widget _buildSegmentCard(Map<String, dynamic> seg, int segIndex, int totalSegments) {
    final dep = seg['departure'] as Map<String, dynamic>;
    final arr = seg['arrival'] as Map<String, dynamic>;
    final carrier = seg['carrierCode'] as String;
    final flightNo = seg['number'] as String;
    final depAt = DateTime.parse(dep['at'] as String);
    final arrAt = DateTime.parse(arr['at'] as String);
    
    final depTimeFmt = DateFormat('HH:mm').format(depAt);
    final depDateFmt = DateFormat('MMM dd').format(depAt);
    final arrTimeFmt = DateFormat('HH:mm').format(arrAt);
    final arrDateFmt = DateFormat('MMM dd').format(arrAt);

    final duration = arrAt.difference(depAt);
    final durationStr = "${duration.inHours}h ${duration.inMinutes % 60}m";

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: segIndex < totalSegments - 1 ? 20 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: subtleGrey.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              // Airline info
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: subtleGrey.withOpacity(0.3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _airlineLogos[carrier] ?? 'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=100&h=100&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: primaryColor.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                carrier,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 2),
                        Text(
                          "$carrier $flightNo",
                          style: TextStyle(
                            fontSize: 14,
                            color: darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Flight duration: $durationStr",
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Segment ${segIndex + 1}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Flight path
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
                        const SizedBox(height: 4),
                        Text(
                          dep['iataCode'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkGrey,
                          ),
                        ),
                        Text(
                          depDateFmt,
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                        if (dep['terminal'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Terminal ${dep['terminal']}",
                            style: TextStyle(
                              fontSize: 11,
                              color: accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Flight path visualization
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
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.flight, color: Colors.white, size: 16),
                            ),
                            Expanded(
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          durationStr,
                          style: TextStyle(
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
                        const SizedBox(height: 4),
                        Text(
                          arr['iataCode'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkGrey,
                          ),
                        ),
                        Text(
                          arrDateFmt,
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                        if (arr['terminal'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            "Terminal ${arr['terminal']}",
                            style: TextStyle(
                              fontSize: 11,
                              color: accentOrange,
                              fontWeight: FontWeight.w600,
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
        
        // Layover info
        if (segIndex < totalSegments - 1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  "Layover in ${arr['iataCode']}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Save flight button
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
                        ? LinearGradient(colors: [Colors.grey, Colors.grey.shade600])
                        : LinearGradient(colors: [primaryColor, secondaryColor]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_alreadySaved ? Colors.grey : primaryColor).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: (_alreadySaved || _isSaving) ? null : _saveCurrentOffer,
                    icon: Icon(
                      _alreadySaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
                    label: Text(
                      _alreadySaved 
                          ? "Flight Saved" 
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
          
          // Secondary action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareFlightDetails,
                  icon: Icon(Icons.share, color: primaryColor),
                  label: Text(
                    "Share",
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _proceedToBooking,
                  icon: const Icon(Icons.credit_card, color: Colors.white),
                  label: const Text(
                    "Book Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // Helper methods
  String _formatDuration(String isoDuration) {
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours = match.group(1)!;
      final minutes = match.group(2)!;
      return "${hours}h ${minutes}m";
    }
    return isoDuration.replaceFirst("PT", "").replaceAll("H", "h ").replaceAll("M", "m");
  }

  String _getAirlineName(String code) {
    final airlines = {
      'MH': 'Malaysia Airlines',
      'AK': 'AirAsia',
      'SQ': 'Singapore Airlines',
      'TG': 'Thai Airways',
      'GA': 'Garuda Indonesia',
      'EK': 'Emirates',
    };
    return airlines[code] ?? 'Airline $code';
  }

  void _copyOfferIdToClipboard() {
    // Copy offer ID to clipboard
    _showMessage('Booking reference copied to clipboard');
  }

  void _shareFlightDetails() {
    // Share flight details
    _showMessage('Sharing flight details...');
  }

  void _proceedToBooking() {
    // Navigate to booking page
    _showMessage('Proceeding to booking...');
  }
}

// Simple Color extension to darken a color by a fraction
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}