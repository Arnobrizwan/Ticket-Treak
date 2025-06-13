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

class _SavedFlightsScreenState extends State<SavedFlightsScreen>
    with TickerProviderStateMixin {
  // Violin color palette (matching OnboardingScreen)
  static const Color backgroundColor = Color(0xFFF5F0E1);
  static const Color primaryColor = Color(0xFF5C2E00);
  static const Color secondaryColor = Color(0xFF8B5000);
  static const Color textColor = Color(0xFF35281E);
  static const Color subtleGrey = Color(0xFFDAC1A7);
  static const Color darkGrey = Color(0xFF7E5E3C);
  static const Color accentOrange = Color(0xFFD4A373);
  static const Color successColor = Color(0xFF8B5000);

  late final String _userId;
  final _firestore = FirebaseFirestore.instance;

  // Animation controllers
  late final AnimationController _slideController;
  late final AnimationController _fadeController;
  late final AnimationController _refreshController;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _refreshAnimation;

  bool _isRefreshing = false;

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
      duration: const Duration(milliseconds: 800),
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

    // Simulate a short delay; Firestore stream updates automatically
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isRefreshing = false);
    _refreshController.reverse();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Saved flights refreshed', style: TextStyle(fontSize: 14)),
            ],
          ),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
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
          _buildModernAppBar(),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border,
                    size: 60, color: primaryColor),
              ),
              const SizedBox(height: 24),
              const Text(
                "Login Required",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please sign in to view and manage your saved flights",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: darkGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                icon: const Icon(Icons.login, color: Colors.white, size: 18),
                label: const Text(
                  "Sign In",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          fontSize: 16,
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              "Saved Flights",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -16,
                bottom: -16,
                child: Container(
                  width: 60,
                  height: 60,
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
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
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
          child: AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  icon:
                      const Icon(Icons.refresh, color: Colors.white, size: 20),
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
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData) {
              return _buildLoadingState();
            }

            final docs = snapshot.data!.docs;

            // Sort in memory so newest appear first
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['savedAt'] as Timestamp?;
              final bTime = bData['savedAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Descending order
            });

            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            return AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 40 * _slideAnimation.value),
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
    return SizedBox(
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
              child: const Icon(Icons.bookmark, color: Colors.white, size: 32),
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
            const SizedBox(height: 6),
            const Text(
              "Just a moment",
              style: TextStyle(
                fontSize: 12,
                color: darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
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
                    size: 48, color: Colors.red.shade700),
              ),
              const SizedBox(height: 20),
              const Text(
                "Unable to load saved flights",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Please check your connection and try again",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: darkGrey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshList,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  "Try Again",
                  style: TextStyle(fontSize: 14),
                ),
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: subtleGrey.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border,
                    size: 60, color: darkGrey),
              ),
              const SizedBox(height: 24),
              const Text(
                "No Saved Flights Yet",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Start saving your favorite flights to see them here.\nEasily compare and book later!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: darkGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/flight-search'),
                    icon:
                        const Icon(Icons.search, color: Colors.white, size: 16),
                    label: const Text(
                      "Search Flights",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back,
                        color: primaryColor, size: 16),
                    label: const Text(
                      "Go Back",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          padding: const EdgeInsets.all(20),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      accentOrange.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    const Icon(Icons.bookmark, color: primaryColor, size: 28),
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
                    const SizedBox(height: 2),
                    Text(
                      "${docs.length} flight${docs.length == 1 ? '' : 's'} saved for later",
                      style: const TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: successColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${docs.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Individual flight cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildEnhancedFlightCard(docs[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedFlightCard(QueryDocumentSnapshot doc, int index) {
    try {
      final saved = doc.data() as Map<String, dynamic>;
      final offer = saved['rawOfferJson'] as Map<String, dynamic>? ?? {};

      if (offer.isEmpty) {
        return _buildErrorCard("Invalid flight data", index);
      }

      // Parse flight data safely
      final priceInfo = offer['price'] as Map<String, dynamic>? ?? {};
      final totalPrice = priceInfo['total'] as String? ?? 'N/A';
      final currency = priceInfo['currency'] as String? ?? 'MYR';

      final itineraries = offer['itineraries'] as List<dynamic>? ?? [];
      if (itineraries.isEmpty) {
        return _buildErrorCard("No itinerary data", index);
      }

      final firstItin = itineraries[0] as Map<String, dynamic>;
      final durationStr = firstItin['duration'] as String? ?? 'N/A';
      final segments = firstItin['segments'] as List<dynamic>? ?? [];
      if (segments.isEmpty) {
        return _buildErrorCard("No segment data", index);
      }

      final firstSeg = segments[0] as Map<String, dynamic>;
      final dep = firstSeg['departure'] as Map<String, dynamic>? ?? {};
      final arr = firstSeg['arrival'] as Map<String, dynamic>? ?? {};
      final carrier =
          (firstSeg['carrierCode'] as String? ?? 'N/A').toUpperCase();
      final flightNo = firstSeg['number'] as String? ?? 'N/A';

      final depAtStr = dep['at'] as String?;
      final arrAtStr = arr['at'] as String?;
      if (depAtStr == null || arrAtStr == null) {
        return _buildErrorCard("Invalid time data", index);
      }

      final depAt = DateTime.parse(depAtStr);
      final arrAt = DateTime.parse(arrAtStr);
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
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 28),
              SizedBox(height: 6),
              Text(
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
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header: Logo / Flight No / Price / Saved Date / Delete Icon ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.05),
                      secondaryColor.withOpacity(0.05)
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Airline logo (via pics.avs.io) ──
                    Container(
                      width: 44,
                      height: 44,
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
                          "https://pics.avs.io/100/100/$carrier.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // fallback: two-letter code on colored background
                            return Container(
                              color: _getAirlineColor(carrier),
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

                    // ── Airline name & flight number ──
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Price & saved date ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$currency $totalPrice",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: successColor,
                          ),
                        ),
                        if (savedDate != null)
                          Text(
                            "Saved ${DateFormat('MMM dd').format(savedDate)}",
                            style: const TextStyle(
                              fontSize: 10,
                              color: darkGrey,
                            ),
                          ),
                      ],
                    ),

                    // ── Delete icon button ──
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () async {
                        final confirmed =
                            await _showDeleteConfirmation(context);
                        if (confirmed == true) {
                          await _deleteSavedFlight(doc.id);
                        }
                      },
                    ),
                  ],
                ),
              ),

              // ── Flight timeline: departure → arrival ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Departure column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                depTimeFmt,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dep['iataCode'] as String? ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                depDateFmt,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Flight path graphic
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            primaryColor,
                                            secondaryColor
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.flight,
                                        color: Colors.white, size: 16),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            secondaryColor,
                                            primaryColor
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDuration(durationStr),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: darkGrey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (segments.length > 1)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${segments.length - 1} stop${segments.length > 2 ? 's' : ''}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: accentOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Arrival column
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                arrTimeFmt,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                arr['iataCode'] as String? ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd').format(arrAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: darkGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action buttons: “View Details” & “Book Now”
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToDetails(saved, offer),
                            icon: const Icon(Icons.info_outline,
                                color: primaryColor, size: 18),
                            label: const Text(
                              "View Details",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/seat-selection',
                                arguments: {
                                  'offer': offer,
                                  'originCode':
                                      saved['originCode'] as String? ?? '',
                                  'destinationCode':
                                      saved['destinationCode'] as String? ?? '',
                                  'departureDate':
                                      saved['departureDateStr'] as String? ??
                                          '',
                                  'adults': saved['adults'] as int? ?? 1,
                                  'travelClass':
                                      saved['travelClass'] as String? ?? '',
                                  'direct': saved['direct'] as bool? ?? false,
                                  'isStudentFare':
                                      saved['isStudentFare'] as bool? ?? false,
                                },
                              );
                            },
                            icon: const Icon(Icons.flight_takeoff,
                                color: Colors.white, size: 18),
                            label: const Text(
                              "Book Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
    } catch (e) {
      return _buildErrorCard("Error loading flight: $e", index);
    }
  }

  Widget _buildErrorCard(String message, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Saved Flight ${index + 1}: $message",
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────
  // Helper methods (including OD → Batik Air)
  // ─────────────────────────────────
  Color _getAirlineColor(String carrier) {
    final colors = {
      'MH': const Color(0xFF5C2E00), // Malaysia Airlines – Brown
      'AK': const Color(0xFFDC2626), // AirAsia – Red
      'SQ': const Color(0xFF8B5000), // Singapore Airlines – Amber Brown
      'TG': const Color(0xFF7C2D92), // Thai Airways – Purple
      'GA': const Color(0xFFB28F5E), // Garuda Indonesia – Muted Brown
      'EK': const Color(0xFFB91C1C), // Emirates – Dark Red
      'OD': const Color(0xFFE53935), // Batik Air – Crimson-ish
    };
    return colors[carrier] ?? primaryColor;
  }

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

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Remove Flight?",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: const Text(
            "This flight will be permanently removed from your saved flights. You can always save it again later.",
            style: TextStyle(color: darkGrey, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: darkGrey, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                "Remove",
                style: TextStyle(color: Colors.white, fontSize: 14),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Flight removed from saved flights',
                    style: TextStyle(fontSize: 14)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing flight: $e',
                style: const TextStyle(fontSize: 14)),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  void _navigateToDetails(
      Map<String, dynamic> saved, Map<String, dynamic> offer) {
    Navigator.pushNamed(
      context,
      '/flight-detail',
      arguments: {
        'offer': offer,
        'originCode': saved['originCode'] as String? ?? '',
        'destinationCode': saved['destinationCode'] as String? ?? '',
        'departureDate': saved['departureDateStr'] as String? ?? '',
        'adults': saved['adults'] as int? ?? 1,
        'travelClass': saved['travelClass'] as String? ?? '',
        'direct': saved['direct'] as bool? ?? false,
        'isStudentFare': saved['isStudentFare'] as bool? ?? false,
      },
    );
  }

  void _bookFlight(Map<String, dynamic> offer) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Redirecting to booking...', style: TextStyle(fontSize: 14)),
            ],
          ),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
}
