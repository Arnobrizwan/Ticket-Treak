// lib/screens/user/flight/saved_flights_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedFlightsScreen extends StatefulWidget {
  const SavedFlightsScreen({Key? key}) : super(key: key);

  @override
  State<SavedFlightsScreen> createState() => _SavedFlightsScreenState();
}

class _SavedFlightsScreenState extends State<SavedFlightsScreen> with TickerProviderStateMixin {
  // Violin color palette (same as everywhere)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor = Color(0xFF5C2E00);     // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000);   // Amber Brown
  static const Color textColor = Color(0xFF35281E);        // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7);       // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C);         // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373);     // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E);      // Muted Brown

  late final String _userId;
  final _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _refreshAnimation;

  bool _isRefreshing = false;

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
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';
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
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    _refreshController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    setState(() => _isRefreshing = false);
    _refreshController.reverse();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Saved flights refreshed'),
        backgroundColor: accentGreen,
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
    if (_userId.isEmpty) {
      return _buildNotLoggedInState();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildEnhancedAppBar(),
          _buildSavedFlightsList(),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildSimpleAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: subtleGrey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.login, size: 64, color: darkGrey),
              ),
              const SizedBox(height: 24),
              const Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Please log in to view and manage your saved flights",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      title: const Text(
        "Saved Flights",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
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
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Saved Flights",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                right: -50,
                top: -50,
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
          child: AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _isRefreshing ? null : _refreshList,
                  tooltip: "Refresh",
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavedFlightsList() {
    return SliverToBoxAdapter(
      child: RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: primaryColor,
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('savedFlights')
              .where('userId', isEqualTo: _userId)
              .orderBy('savedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            return AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * _slideAnimation.value),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildFlightsList(docs),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
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
                child: const Icon(Icons.bookmark, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Loading your saved flights...",
              style: TextStyle(
                fontSize: 16,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Error loading saved flights: $error",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshList,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: subtleGrey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bookmark_border, size: 64, color: darkGrey),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Saved Flights Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Start saving your favorite flights to see them here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/flight-search'),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                "Search Flights",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back, color: primaryColor),
              label: Text(
                "Go Back",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildFlightsList(List<QueryDocumentSnapshot> docs) {
    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), accentOrange.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bookmark, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Saved Flights",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "${docs.length} flight${docs.length == 1 ? '' : 's'} saved",
                      style: TextStyle(
                        fontSize: 14,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${docs.length}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Flight cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildEnhancedFlightCard(docs[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedFlightCard(QueryDocumentSnapshot doc, int index) {
    final saved = doc.data() as Map<String, dynamic>;
    final offer = saved['rawOfferJson'] as Map<String, dynamic>;

    // Parse flight data
    final priceInfo = offer['price'] as Map<String, dynamic>;
    final totalPrice = priceInfo['total'] as String;
    final currency = priceInfo['currency'] as String;

    final itineraries = offer['itineraries'] as List<dynamic>;
    final firstItin = itineraries[0] as Map<String, dynamic>;
    final durationStr = firstItin['duration'] as String;
    final segments = firstItin['segments'] as List<dynamic>;
    final firstSeg = segments[0] as Map<String, dynamic>;
    final dep = firstSeg['departure'] as Map<String, dynamic>;
    final arr = firstSeg['arrival'] as Map<String, dynamic>;
    final carrier = firstSeg['carrierCode'] as String;
    final flightNo = firstSeg['number'] as String;
    final depAt = DateTime.parse(dep['at'] as String);
    final arrAt = DateTime.parse(arr['at'] as String);

    final depTimeFmt = DateFormat('HH:mm').format(depAt);
    final arrTimeFmt = DateFormat('HH:mm').format(arrAt);
    final depDateFmt = DateFormat('MMM dd').format(depAt);

    // Saved date
    final savedAt = saved['savedAt'] as Timestamp?;
    final savedDate = savedAt?.toDate();

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade700],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_forever, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            const Text(
              "Remove",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (_) async {
        await _deleteSavedFlight(doc.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            // Header with saved date and index
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
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Saved Flight ${index + 1}",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (savedDate != null)
                    Text(
                      "Saved ${DateFormat('MMM dd').format(savedDate)}",
                      style: TextStyle(
                        color: darkGrey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Airline info with logo
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
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$currency $totalPrice",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: accentGreen,
                            ),
                          ),
                          if (saved['isStudentFare'] == true)
                            Text(
                              "Student Fare",
                              style: TextStyle(
                                fontSize: 10,
                                color: accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Flight timeline
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
                          ],
                        ),
                      ),

                      // Flight path
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
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
                                Icon(Icons.flight, color: primaryColor, size: 20),
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
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(durationStr),
                              style: TextStyle(
                                fontSize: 12,
                                color: darkGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (segments.length > 1)
                              Text(
                                "${segments.length - 1} stop${segments.length > 2 ? 's' : ''}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
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
                              DateFormat('MMM dd').format(arrAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToDetails(saved, offer),
                          icon: Icon(Icons.info_outline, color: primaryColor),
                          label: Text(
                            "View Details",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
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
                          onPressed: () => _bookFlight(offer),
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
            ),
          ],
        ),
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

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Remove Saved Flight?",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This flight will be permanently removed from your saved flights.",
            style: TextStyle(color: darkGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: darkGrey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSavedFlight(String docId) async {
    try {
      await _firestore.collection('savedFlights').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Flight removed from saved flights'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing flight: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToDetails(Map<String, dynamic> saved, Map<String, dynamic> offer) {
    Navigator.pushNamed(
      context,
      '/flight-detail',
      arguments: {
        'offer': offer,
        'originCode': saved['originCode'] as String,
        'destinationCode': saved['destinationCode'] as String,
        'departureDate': saved['departureDateStr'] as String,
        'adults': saved['adults'] as int,
        'travelClass': saved['travelClass'] as String,
        'direct': saved['direct'] as bool,
        'isStudentFare': saved['isStudentFare'] as bool,
      },
    );
  }

  void _bookFlight(Map<String, dynamic> offer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Proceeding to booking...'),
        backgroundColor: accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Color extension to darken a color by [amount]:
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}