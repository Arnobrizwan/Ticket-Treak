// lib/screens/user/flight/flight_results_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/services/amadeus_service.dart';

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({super.key});

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> with TickerProviderStateMixin {
  // Violin color palette (matching FlightSearchPage)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor = Color(0xFF5C2E00);     // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000);   // Amber Brown
  static const Color textColor = Color(0xFF35281E);        // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7);       // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C);         // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373);     // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E);      // Muted Brown

  bool _isLoading = true;
  String? _errorMessage;
  
  // Flight offers data
  List<dynamic> _allFlightOffers = [];
  List<dynamic> _displayedOffers = [];
  
  // Price filter state
  double _minPriceFilter = 0.0;
  double _maxPriceFilter = 0.0;
  double _currentMinPrice = 0.0;
  double _currentMaxPrice = 0.0;
  
  // Currency and sorting
  String _selectedCurrency = 'MYR';
  Map<String, double> _exchangeRates = {
    'MYR': 1.0,
    'USD': 0.21,
    'EUR': 0.19,
    'SGD': 0.29,
    'THB': 7.45,
    'IDR': 3205.0,
  };
  
  bool _sortAscending = true;
  String _sortBy = 'price'; // 'price', 'duration', 'departure'
  
  // Search parameters
  late final String originCode;
  late final String destinationCode;
  late final String departureDateStr;
  late final int adults;
  late final String travelClass;
  late final bool direct;
  late final bool isStudentFare;
  late final bool needsHotel;
  late final bool needsTransport;
  late final bool isFlexibleDates;
  
  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _cardController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _cardAnimation;

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
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    
    _loadingController.repeat();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    originCode = args['originCode'] as String;
    destinationCode = args['destinationCode'] as String;
    departureDateStr = args['departureDate'] as String;
    adults = args['adults'] as int;
    travelClass = args['travelClass'] as String;
    direct = args['direct'] as bool;
    isStudentFare = args['isStudentFare'] as bool;
    needsHotel = args['needsHotel'] ?? false;
    needsTransport = args['needsTransport'] ?? false;
    isFlexibleDates = args['isFlexibleDates'] ?? false;
    
    _fetchFlightOffers();
  }

  Future<void> _fetchFlightOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allFlightOffers = [];
      _displayedOffers = [];
    });

    try {
      final service = AmadeusService();
      final results = await service.searchFlights(
        originCode: originCode,
        destinationCode: destinationCode,
        departureDate: departureDateStr,
        direct: direct,
        adults: adults,
        travelClass: travelClass,
      );

      // Compute min/max price for filtering
      double lowest = double.infinity;
      double highest = 0.0;
      
      for (final offer in results) {
        final priceInfo = offer['price'] as Map<String, dynamic>;
        final totalPriceStr = priceInfo['total'] as String;
        final priceValue = double.tryParse(totalPriceStr) ?? 0.0;
        if (priceValue < lowest) lowest = priceValue;
        if (priceValue > highest) highest = priceValue;
      }

      if (lowest == double.infinity) lowest = 0.0;

      setState(() {
        _isLoading = false;
        _allFlightOffers = results;
        _displayedOffers = List<dynamic>.from(results);
        _minPriceFilter = lowest;
        _maxPriceFilter = highest;
        _currentMinPrice = lowest;
        _currentMaxPrice = highest;
      });
      
      _cardController.forward();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildEnhancedAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState(_errorMessage!))
          else if (_displayedOffers.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else ...[
            _buildSearchSummary(),
            if (needsHotel || needsTransport) _buildAdditionalServices(),
            _buildFilterAndSort(),
            _buildResultsList(),
          ],
        ],
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
        title: Text(
          "$originCode → $destinationCode",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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
        // Currency selector
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: PopupMenuButton<String>(
            initialValue: _selectedCurrency,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedCurrency, style: const TextStyle(color: Colors.white, fontSize: 12)),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
              ],
            ),
            onSelected: (String currency) {
              setState(() {
                _selectedCurrency = currency;
              });
            },
            itemBuilder: (BuildContext context) {
              return _exchangeRates.keys.map((String currency) {
                return PopupMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSummary() {
    return SliverToBoxAdapter(
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Search Results",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_displayedOffers.length} flights",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentOrange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryItem(Icons.people, "$adults ${adults == 1 ? 'passenger' : 'passengers'}"),
                const SizedBox(width: 16),
                _buildSummaryItem(Icons.business_center, travelClass.toLowerCase()),
                const SizedBox(width: 16),
                _buildSummaryItem(Icons.calendar_today, DateFormat('MMM dd').format(DateTime.parse(departureDateStr))),
              ],
            ),
            if (isStudentFare) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, size: 14, color: accentGreen),
                    const SizedBox(width: 4),
                    Text(
                      "Student discount applied",
                      style: TextStyle(
                        fontSize: 12,
                        color: accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: darkGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: darkGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalServices() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentOrange.withOpacity(0.1), accentGreen.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentOrange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_business, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Additional Services",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (needsHotel) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hotel, color: accentOrange, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            "Hotel included",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (needsTransport) const SizedBox(width: 8),
                ],
                if (needsTransport) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car, color: accentGreen, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            "Transport included",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSort() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            // Filter button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _displayedOffers.isEmpty ? null : () => _showPriceFilterSheet(context),
                icon: const Icon(Icons.filter_list, size: 20),
                label: const Text("Filter"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  side: BorderSide(color: subtleGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sort button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _displayedOffers.isEmpty ? null : () => _showSortOptions(),
                icon: Icon(
                  _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 20,
                ),
                label: Text("Sort by ${_sortBy}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  side: BorderSide(color: subtleGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingAnimation.value * 2 * 3.14159,
                child: Container(
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
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            "Searching for the best flights...",
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This may take a few seconds",
            style: TextStyle(
              fontSize: 14,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchFlightOffers,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: subtleGrey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.airplane_ticket, size: 48, color: darkGrey),
            ),
            const SizedBox(height: 16),
            const Text(
              "No flights found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting your filters or search criteria",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.search),
              label: const Text("Modify Search"),
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

  Widget _buildResultsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final offer = _displayedOffers[index] as Map<String, dynamic>;
          return AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _cardAnimation.value)),
                child: Opacity(
                  opacity: _cardAnimation.value,
                  child: _buildEnhancedOfferCard(offer, index),
                ),
              );
            },
          );
        },
        childCount: _displayedOffers.length,
      ),
    );
  }

  Widget _buildEnhancedOfferCard(Map<String, dynamic> offer, int index) {
    // Parse price and currency
    final priceInfo = offer['price'] as Map<String, dynamic>;
    final totalPrice = priceInfo['total'] as String;
    final currency = priceInfo['currency'] as String;
    final priceValue = double.tryParse(totalPrice) ?? 0.0;
    
    // Convert price to selected currency
    final convertedPrice = _convertCurrency(priceValue, currency, _selectedCurrency);
    
    // Parse itinerary
    final itineraries = offer['itineraries'] as List<dynamic>;
    final firstItin = (itineraries[0] as Map<String, dynamic>);
    final durationStr = firstItin['duration'] as String;
    final segments = firstItin['segments'] as List<dynamic>;
    
    final firstSeg = (segments[0] as Map<String, dynamic>);
    final dep = firstSeg['departure'] as Map<String, dynamic>;
    final arr = firstSeg['arrival'] as Map<String, dynamic>;
    final carrier = firstSeg['carrierCode'] as String;
    final flightNo = firstSeg['number'] as String;
    
    DateTime depAt = DateTime.parse(dep['at'] as String);
    DateTime arrAt = DateTime.parse(arr['at'] as String);
    
    final depTimeFmt = DateFormat('HH:mm').format(depAt);
    final arrTimeFmt = DateFormat('HH:mm').format(arrAt);
    final depDateFmt = DateFormat('MMM dd').format(depAt);
    
    return Container(
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
          // Header with offer number and student discount
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
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Flight Option ${index + 1}",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (isStudentFare)
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
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Airline info with logo
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: subtleGrey.withOpacity(0.3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                                    fontSize: 12,
                                  ),
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
                          Text(
                            "$carrier $flightNo",
                            style: TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "$_selectedCurrency ${_formatCurrency(convertedPrice)}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentGreen,
                          ),
                        ),
                        if (isStudentFare)
                          Text(
                            "30% off applied",
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            originCode,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destinationCode,
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
                      child: OutlinedButton(
                        onPressed: () => _showFlightDetails(offer),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _bookFlight(offer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Book Now",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
    );
  }

  // Helper methods
  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    // Convert to MYR first, then to target currency
    double amountInMYR = amount;
    if (fromCurrency != 'MYR') {
      amountInMYR = amount / (_exchangeRates[fromCurrency] ?? 1.0);
    }
    
    return amountInMYR * (_exchangeRates[toCurrency] ?? 1.0);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

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

  // Action methods
  void _showFlightDetails(Map<String, dynamic> offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subtleGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      "Flight Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Add detailed flight information here
                    Text(
                      "Detailed flight information would go here...",
                      style: TextStyle(color: darkGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bookFlight(Map<String, dynamic> offer) {
    // Navigate to booking page or show booking modal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Proceeding to booking...'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sort by",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('price', 'Price', Icons.attach_money),
            _buildSortOption('duration', 'Duration', Icons.schedule),
            _buildSortOption('departure', 'Departure Time', Icons.flight_takeoff),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? primaryColor : darkGrey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? primaryColor : textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: primaryColor,
            )
          : null,
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
        _sortDisplayedOffers();
        Navigator.pop(context);
      },
    );
  }

  void _showPriceFilterSheet(BuildContext context) {
    double tempMin = _currentMinPrice;
    double tempMax = _currentMaxPrice;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter by Price",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: darkGrey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$_selectedCurrency ${_formatCurrency(_convertCurrency(tempMin, 'MYR', _selectedCurrency))}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "$_selectedCurrency ${_formatCurrency(_convertCurrency(tempMax, 'MYR', _selectedCurrency))}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    min: _minPriceFilter,
                    max: _maxPriceFilter,
                    divisions: (_maxPriceFilter - _minPriceFilter).round().clamp(1, 100),
                    values: RangeValues(tempMin, tempMax),
                    activeColor: primaryColor,
                    inactiveColor: subtleGrey,
                    onChanged: (RangeValues values) {
                      setLocalState(() {
                        tempMin = values.start.clamp(_minPriceFilter, _maxPriceFilter);
                        tempMax = values.end.clamp(_minPriceFilter, _maxPriceFilter);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentMinPrice = tempMin;
                          _currentMaxPrice = tempMax;
                        });
                        _applyPriceFilterAndSort();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Apply Filter",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyPriceFilterAndSort() {
    final filtered = _allFlightOffers.where((offer) {
      final priceInfo = offer['price'] as Map<String, dynamic>;
      final totalPrice = double.tryParse(priceInfo['total'] as String) ?? 0.0;
      return totalPrice >= _currentMinPrice && totalPrice <= _currentMaxPrice;
    }).toList();

    setState(() {
      _displayedOffers = filtered;
    });

    _sortDisplayedOffers();
  }

  void _sortDisplayedOffers() {
    _displayedOffers.sort((a, b) {
      switch (_sortBy) {
        case 'price':
          final priceA = double.tryParse((a['price']['total'] as String)) ?? 0.0;
          final priceB = double.tryParse((b['price']['total'] as String)) ?? 0.0;
          return _sortAscending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
        
        case 'duration':
          final itinA = (a['itineraries'][0] as Map<String, dynamic>);
          final itinB = (b['itineraries'][0] as Map<String, dynamic>);
          final durA = _parseDurationToMinutes(itinA['duration'] as String);
          final durB = _parseDurationToMinutes(itinB['duration'] as String);
          return _sortAscending ? durA.compareTo(durB) : durB.compareTo(durA);
        
        case 'departure':
          final depA = DateTime.parse(a['itineraries'][0]['segments'][0]['departure']['at']);
          final depB = DateTime.parse(b['itineraries'][0]['segments'][0]['departure']['at']);
          return _sortAscending ? depA.compareTo(depB) : depB.compareTo(depA);
        
        default:
          return 0;
      }
    });
    setState(() {});
  }

  int _parseDurationToMinutes(String isoDuration) {
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours = int.tryParse(match.group(1)!) ?? 0;
      final minutes = int.tryParse(match.group(2)!) ?? 0;
      return hours * 60 + minutes;
    }
    return int.tryParse(isoDuration.replaceAll(RegExp(r'\D+'), '')) ?? 0;
  }
}