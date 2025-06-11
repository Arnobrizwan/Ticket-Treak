// lib/screens/user/flight/flight_results_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:ticket_trek/services/amadeus_service.dart';

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({super.key});

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage>
    with TickerProviderStateMixin {
  // Violin color palette (matching OnboardingScreen)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange    = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown
  static const Color successColor    = Color(0xFF8B5000);  // Success
  static const Color warningColor    = Color(0xFFD4A373);  // Warning

  // State fields
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _allFlightOffers = [];
  List<dynamic> _displayedOffers = [];
  Map<String, dynamic> _carrierDictionary = {};

  // Hotel & Transfer data with loading states
  final Map<int, List<dynamic>> _hotelOffersMap     = {};
  final Map<int, List<dynamic>> _transferOptionsMap = {};
  final Map<int, bool> _hotelLoadingMap     = {};
  final Map<int, bool> _transferLoadingMap  = {};

  // Price filter state
  double _minPriceFilter   = 0.0;
  double _maxPriceFilter   = 0.0;
  double _currentMinPrice  = 0.0;
  double _currentMaxPrice  = 0.0;

  // Currency & sorting
  String _selectedCurrency = 'MYR';
  final Map<String, double> _exchangeRates = {
    'MYR': 1.0,
    'USD': 0.21,
    'EUR': 0.19,
    'SGD': 0.29,
    'THB': 7.45,
    'IDR': 3205.0,
  };

  final Map<String, String> _currencySymbols = {
    'MYR': 'RM',
    'USD': '\$',
    'EUR': '€',
    'SGD': 'S\$',
    'THB': '฿',
    'IDR': 'Rp',
  };

  bool _sortAscending = true;
  String _sortBy = 'price';

  // Search parameters (passed via Navigator)
  late String originCode;
  late String destinationCode;
  late String departureDateStr;
  late int adults;
  late String travelClass;
  late bool direct;
  late bool isStudentFare;
  late bool needsHotel;
  late bool needsTransport;
  late bool isFlexibleDates;
  bool _didFetchArgs = false;

  // Animation controllers
  late final AnimationController _loadingController;
  late final AnimationController _cardController;
  late final AnimationController _pulseController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _cardAnimation;
  late Animation<double> _pulseAnimation;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadingController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _cardController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchArgs) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      originCode = args['originCode']       as String;
      destinationCode = args['destinationCode'] as String;
      departureDateStr = args['departureDate']  as String;
      adults = args['adults'] as int;
      travelClass = args['travelClass'] as String;
      direct = args['direct'] as bool;
      isStudentFare = args['isStudentFare'] as bool;
      needsHotel = args['needsHotel'] as bool? ?? false;
      needsTransport = args['needsTransport'] as bool? ?? false;
      isFlexibleDates = args['isFlexibleDates'] as bool? ?? false;
      _didFetchArgs = true;
      _refreshAndRebuild();
    }
  }

  ///  --- 1) Kick off flight + optional hotel + optional transfer fetch
  Future<void> _refreshAndRebuild() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allFlightOffers.clear();
      _displayedOffers.clear();
      _carrierDictionary.clear();
      _hotelOffersMap.clear();
      _transferOptionsMap.clear();
      _hotelLoadingMap.clear();
      _transferLoadingMap.clear();
    });

    try {
      final service = AmadeusService();
      final flightResponse = await service.searchFlights(
        originCode: originCode,
        destinationCode: destinationCode,
        departureDate: departureDateStr,
        direct: direct,
        adults: adults,
        travelClass: travelClass,
        currencyCode: _selectedCurrency,
        maxResults: 15,
      );

      // The v2 response returns:
      //   { "data": [ <offer1>, <offer2>, … ], "dictionaries": { "carriers": { "AA": "American Airlines", … } } }
      final List<dynamic> offers = flightResponse['data'] as List<dynamic>;
      final Map<String, dynamic> dicts = flightResponse['dictionaries'] as Map<String, dynamic>;

      // Extract the 'carriers' dictionary so that we can look up full airline names.
      _carrierDictionary = (dicts['carriers'] as Map<String, dynamic>? ?? {});

      // Figure out min/max price for filters:
      double lowest  = double.infinity;
      double highest = 0.0;
      for (final offer in offers) {
        final priceInfo = offer['price'] as Map<String, dynamic>;
        final totalPriceStr = priceInfo['total'] as String;
        final priceValue = double.tryParse(totalPriceStr) ?? 0.0;
        if (priceValue < lowest)  lowest = priceValue;
        if (priceValue > highest) highest = priceValue;
      }
      if (lowest == double.infinity) lowest = 0.0;

      setState(() {
        _isLoading = false;
        _allFlightOffers = List<dynamic>.from(offers);
        _displayedOffers = List<dynamic>.from(offers);
        _minPriceFilter = lowest;
        _maxPriceFilter = highest;
        _currentMinPrice = lowest;
        _currentMaxPrice = highest;
      });

      _sortDisplayedOffers();
      _cardController.forward();

      // If user also wants hotels or transfers, fetch them in the background.
      if (needsHotel) {
        _fetchHotelsForAllOffers(offers);
      }
      if (needsTransport) {
        _fetchTransfersForAllOffers(offers);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// 2) Fetch Hotels for each flight (up to 10 offers)
  Future<void> _fetchHotelsForAllOffers(List<dynamic> offers) async {
    final service = AmadeusService();
    for (int i = 0; i < offers.length && i < 10; i++) {
      setState(() {
        _hotelLoadingMap[i] = true;
      });

      try {
        final dt = DateTime.parse(departureDateStr);
        final checkIn = departureDateStr;
        final checkOut = DateFormat('yyyy-MM-dd').format(dt.add(const Duration(days: 1)));

        final hotelResults = await service.searchHotels(
          cityCode: destinationCode,
          checkInDate: checkIn,
          checkOutDate: checkOut,
          adults: adults,
          currencyCode: _selectedCurrency,
          maxResults: 4,
        );
        setState(() {
          _hotelOffersMap[i] = hotelResults;
          _hotelLoadingMap[i] = false;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Hotel search error for offer $i: $e');
        }
        setState(() {
          _hotelOffersMap[i] = [];
          _hotelLoadingMap[i] = false;
        });
      }
    }
  }

  /// 3) Fetch Transfers for each flight’s first segment arrival airport (up to 10 offers)
  Future<void> _fetchTransfersForAllOffers(List<dynamic> offers) async {
    final service = AmadeusService();
    for (int i = 0; i < offers.length && i < 10; i++) {
      setState(() {
        _transferLoadingMap[i] = true;
      });

      try {
        final firstItin = offers[i]['itineraries'][0] as Map<String, dynamic>;
        final firstSeg  = firstItin['segments'][0]  as Map<String, dynamic>;
        final arr       = firstSeg['arrival']       as Map<String, dynamic>;
        final airportCode = arr['iataCode'] as String;

        // The API expects a string like "2025-06-04T14:30"
        final pickupDateTime = DateTime.parse(arr['at'] as String);
        final pickupStr = DateFormat("yyyy-MM-dd'T'HH:mm").format(pickupDateTime);

        final transfers = await service.searchAirportTransfers(
          airportCode: airportCode,
          pickupDateTime: pickupStr,
          currencyCode: _selectedCurrency,
        );
        setState(() {
          _transferOptionsMap[i] = transfers;
          _transferLoadingMap[i] = false;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Transfer search error for offer $i: $e');
        }
        setState(() {
          _transferOptionsMap[i] = [];
          _transferLoadingMap[i] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildEnhancedLoadingState())
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildEnhancedErrorState(_errorMessage!))
          else if (_displayedOffers.isEmpty)
            SliverFillRemaining(child: _buildEnhancedEmptyState())
          else ...[
            _buildEnhancedSearchSummary(),
            if (needsHotel || needsTransport) _buildServicesSection(),
            _buildFilterSortSection(),
            _buildEnhancedResultsList(),
          ],
        ],
      ),
    );
  }

  /// AppBar with route + currency selector
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
            const Icon(Icons.flight, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              "$originCode → $destinationCode",
              style: const TextStyle(
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
                right: -40,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: PopupMenuButton<String>(
            initialValue: _selectedCurrency,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currencySymbols[_selectedCurrency] ?? _selectedCurrency,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
            onSelected: (String currency) {
              setState(() {
                _selectedCurrency = currency;
              });
              _refreshAndRebuild();
            },
            itemBuilder: (BuildContext context) {
              return _exchangeRates.keys.map((String currency) {
                return PopupMenuItem<String>(
                  value: currency,
                  child: Row(
                    children: [
                      Text(
                        _currencySymbols[currency] ?? currency,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(currency),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  /// Search summary (number of flights, basic criteria)
  Widget _buildEnhancedSearchSummary() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
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
                  child: Icon(Icons.search, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Flight Search Results",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Found ${_displayedOffers.length} flights",
                        style: TextStyle(
                          fontSize: 12,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: successColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_displayedOffers.length}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _buildInfoChip(Icons.people, "$adults passenger${adults > 1 ? 's' : ''}", primaryColor),
                _buildInfoChip(Icons.business_center, travelClass.toLowerCase(), secondaryColor),
                _buildInfoChip(
                  Icons.calendar_today,
                  DateFormat('MMM dd').format(DateTime.parse(departureDateStr)),
                  accentOrange,
                ),
                if (direct)
                  _buildInfoChip(Icons.trending_flat, "Direct", successColor),
                if (isStudentFare)
                  _buildInfoChip(Icons.school, "Student Fare", accentGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentOrange.withOpacity(0.1), accentGreen.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentOrange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_business, color: primaryColor, size: 24),
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
                          Icon(Icons.hotel, color: accentOrange, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            "Hotels",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Available below",
                            style: TextStyle(
                              fontSize: 10,
                              color: darkGrey,
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
                          Icon(Icons.directions_car, color: accentGreen, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            "Transfers",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Text(
                            "Available below",
                            style: TextStyle(
                              fontSize: 10,
                              color: darkGrey,
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

  Widget _buildFilterSortSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, subtleGrey.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _displayedOffers.isEmpty
                      ? null
                      : () => _showPriceFilterSheet(context),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryColor,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, subtleGrey.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _displayedOffers.isEmpty
                      ? null
                      : () => _showSortOptions(),
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 18,
                    color: primaryColor,
                  ),
                  label: Text(
                    "Sort: $_sortBy",
                    style: TextStyle(color: primaryColor, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: primaryColor,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flight, color: Colors.white, size: 32),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "Finding the best flights for you...",
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Searching through hundreds of airlines",
            style: TextStyle(
              fontSize: 12,
              color: darkGrey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 160,
            height: 4,
            decoration: BoxDecoration(
              color: subtleGrey,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _loadingAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 56, color: Colors.red.shade700),
            ),
            const SizedBox(height: 20),
            Text(
              "Unable to find flights",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message.contains('404')
                ? "No flights available for this route"
                : "Please check your connection and try again",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshAndRebuild,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Search"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  Widget _buildEnhancedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: subtleGrey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.airplane_ticket, size: 56, color: darkGrey),
            ),
            const SizedBox(height: 20),
            const Text(
              "No flights match your filters",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Try adjusting your price range or travel dates",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentMinPrice = _minPriceFilter;
                  _currentMaxPrice = _maxPriceFilter;
                });
                _applyPriceFilterAndSort();
              },
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text("Clear Filters"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  /// 4) Build the list of flight cards
  Widget _buildEnhancedResultsList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final offer = _displayedOffers[index] as Map<String, dynamic>;
          return AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _cardAnimation.value)),
                child: Opacity(
                  opacity: _cardAnimation.value,
                  child: _buildRealisticFlightCard(offer, index),
                ),
              );
            },
          );
        },
        childCount: _displayedOffers.length,
      ),
    );
  }

  Widget _buildRealisticFlightCard(Map<String, dynamic> offer, int index) {
    // 4.1) Price (with student discount)
    final priceInfo    = offer['price'] as Map<String, dynamic>;
    final totalPriceStr = priceInfo['total'] as String;
    double priceValue  = double.tryParse(totalPriceStr) ?? 0.0;
    if (isStudentFare) {
      priceValue *= 0.7;
    }
    final convertedPrice = _convertCurrency(priceValue, 'MYR', _selectedCurrency);

    // 4.2) Itinerary details
    final itineraries = offer['itineraries'] as List<dynamic>;
    final firstItin   = itineraries[0] as Map<String, dynamic>;
    final durationStr = firstItin['duration'] as String;
    final segments    = firstItin['segments'] as List<dynamic>;
    final firstSeg    = segments[0] as Map<String, dynamic>;
    final dep         = firstSeg['departure'] as Map<String, dynamic>;
    final arr         = firstSeg['arrival']   as Map<String, dynamic>;
    final carrier     = firstSeg['carrierCode'] as String;
    final flightNo    = firstSeg['number'] as String;

    final depAt   = DateTime.parse(dep['at'] as String);
    final arrAt   = DateTime.parse(arr['at'] as String);
    final depTimeFmt = DateFormat('HH:mm').format(depAt);
    final arrTimeFmt = DateFormat('HH:mm').format(arrAt);
    final depDateFmt = DateFormat('MMM dd').format(depAt);

    // 4.3) Airline full name via the dictionary (if available)
    final String airlineName = _carrierDictionary[carrier] as String? ?? 'Airline $carrier';

    // 4.4) Build a "logo URL" from the carrier code
    //     (Here we use a free CDN from Skyscanner / AirHex. Replace with your preferred provider.)
    final String logoUrl = 'https://content.airhex.com/content/logos/airlines_${carrier.toLowerCase()}_200_200_s.png';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          // ─── 4.5 Header: Airline logo + name + price ─────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.05), secondaryColor.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                //  Logo (40×40)
                Container(
                  width: 44,
                  height: 44,
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
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // If the network logo fails, show the carrier code text
                        return Center(
                          child: Text(
                            carrier,
                            style: const TextStyle(
                              color: primaryColor,
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
                        airlineName,
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
                          fontSize: 12,
                          color: darkGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${_currencySymbols[_selectedCurrency]}${_formatCurrency(convertedPrice)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: successColor,
                      ),
                    ),
                    if (isStudentFare)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: successColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "30% OFF",
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
          ),

          // ─── 4.6 Flight details: Departure → Flight Path → Arrival ───────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                          const SizedBox(height: 2),
                          Text(
                            dep['iataCode'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
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

                    // Flight path bar
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
                                    gradient: LinearGradient(
                                      colors: [primaryColor, secondaryColor],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.flight, color: Colors.white, size: 14),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [secondaryColor, primaryColor],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
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
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: warningColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${segments.length - 1} stop${segments.length > 2 ? 's' : ''}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
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
                          const SizedBox(height: 2),
                          Text(
                            arr['iataCode'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
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

                // ─── 4.7 Hotels section (if requested)
                if (needsHotel) ...[
                  _buildHotelSection(index),
                  const SizedBox(height: 16),
                ],

                // ─── 4.8 Transfers section (if requested)
                if (needsTransport) ...[
                  _buildTransferSection(index),
                  const SizedBox(height: 16),
                ],

                // ─── 4.9 Action buttons (Details | Book)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showFlightDetails(offer),
                        icon: Icon(Icons.info_outline, color: primaryColor, size: 18),
                        label: const Text(
                          "Details",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
   Navigator.pushNamed(
     context,
     '/seat-selection', 
    arguments: {
       'offer': offer,
       'originCode': originCode,
       'destinationCode': destinationCode,
       'departureDate': departureDateStr,
       'adults': adults,
       'travelClass': travelClass,
       'direct': direct,
       'isStudentFare': isStudentFare,
     },
    );
  },
                        icon: const Icon(Icons.flight_takeoff, color: Colors.white, size: 18),
                        label: const Text(
                          "Book Flight",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
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

  /// 4.7) Hotel UI
  Widget _buildHotelSection(int flightIndex) {
    final isLoading = _hotelLoadingMap[flightIndex] ?? false;
    final hotels    = _hotelOffersMap[flightIndex] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.hotel, color: accentOrange, size: 20),
            const SizedBox(width: 6),
            Text(
              "Hotels in $destinationCode",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentOrange),
              ),
            ),
          )
        else if (hotels.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: subtleGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.hotel_outlined, color: darkGrey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No hotels available for these dates",
                    style: TextStyle(color: darkGrey, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hotels.length.clamp(0, 4),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final hotel   = hotels[idx] as Map<String, dynamic>;
                final hotelData= hotel['hotel'] as Map<String, dynamic>? ?? {};
                final offers  = hotel['offers'] as List<dynamic>? ?? [];

                final hotelName = hotelData['name'] as String? ?? "Hotel";
                final rating    = hotelData['rating'] as String? ?? "3";
                String price    = "-";
                String currency = _selectedCurrency;

                if (offers.isNotEmpty) {
                  final firstOffer = offers[0] as Map<String, dynamic>;
                  final priceData  = firstOffer['price'] as Map<String, dynamic>? ?? {};
                  price    = priceData['total'] as String? ?? "-";
                  currency = priceData['currency'] as String? ?? _selectedCurrency;
                }

                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentOrange.withOpacity(0.3)),
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
                          Icon(Icons.hotel, size: 18, color: accentOrange),
                          const Spacer(),
                          Row(
                            children: List.generate(
                              int.tryParse(rating) ?? 3,
                              (i) => Icon(Icons.star, size: 10, color: accentOrange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hotelName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        "${_currencySymbols[currency] ?? currency} $price",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentOrange,
                        ),
                      ),
                      Text(
                        "per night",
                        style: TextStyle(
                          fontSize: 10,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 4.8) Transfer UI
  Widget _buildTransferSection(int flightIndex) {
    final isLoading  = _transferLoadingMap[flightIndex] ?? false;
    final transfers  = _transferOptionsMap[flightIndex] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.directions_car, color: accentGreen, size: 20),
            const SizedBox(width: 6),
            Text(
              "Airport Transfers",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            height: 70,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentGreen),
              ),
            ),
          )
        else if (transfers.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: subtleGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_car_outlined, color: darkGrey, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "No transfers available at this time",
                    style: TextStyle(color: darkGrey, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: transfers.length.clamp(0, 4),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final transfer   = transfers[idx] as Map<String, dynamic>;
                final providerData= transfer['provider'] as Map<String, dynamic>? ?? {};
                final priceData   = transfer['price'] as Map<String, dynamic>? ?? {};
                final vehicleData = transfer['vehicle'] as Map<String, dynamic>? ?? {};

                final provider   = providerData['name'] as String? ?? "Transfer Service";
                final price      = priceData['total'] as String? ?? "-";
                final currency   = priceData['currency'] as String? ?? _selectedCurrency;
                final transferType = transfer['transferType'] as String? ?? "PRIVATE";
                final vehicleDesc  = vehicleData['description'] as String? ?? "Standard Vehicle";

                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentGreen.withOpacity(0.3)),
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
                          Icon(
                            transferType == "SHARED" ? Icons.people : Icons.person,
                            size: 18,
                            color: accentGreen,
                          ),
                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transferType.toLowerCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: accentGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        provider,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        vehicleDesc,
                        style: TextStyle(
                          fontSize: 10,
                          color: darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        "${_currencySymbols[currency] ?? currency} $price",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: accentGreen,
                        ),
                      ),
                      Text(
                        "one way",
                        style: TextStyle(
                          fontSize: 10,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 5) Helper methods ───────────────────────────────────────────────

  Color _getAirlineColor(String carrier) {
    final colors = {
      'MH': Color(0xFF5C2E00), // Malaysia Airlines
      'AK': Color(0xFFDC2626), // AirAsia
      'SQ': Color(0xFF8B5000), // Singapore Airlines
      'TG': Color(0xFF7C2D92), // Thai Airways
      'GA': Color(0xFFB28F5E), // Garuda
      'EK': Color(0xFFB91C1C), // Emirates
    };
    return colors[carrier] ?? primaryColor;
  }

  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    double amountInMYR = amount;
    if (fromCurrency != 'MYR') {
      amountInMYR = amount / (_exchangeRates[fromCurrency] ?? 1.0);
    }
    return amountInMYR * (_exchangeRates[toCurrency] ?? 1.0);
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,##0').format(amount);
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
    // If the carrierDictionary was populated, use it
    if (_carrierDictionary.containsKey(code)) {
      return _carrierDictionary[code] as String;
    }
    // Otherwise fallback:
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

  void _showFlightDetails(Map<String, dynamic> offer) {
    Navigator.pushNamed(
      context,
      '/flight-detail',
      arguments: {
        'offer': offer,
        'originCode': originCode,
        'destinationCode': destinationCode,
        'departureDate': departureDateStr,
        'adults': adults,
        'travelClass': travelClass,
        'direct': direct,
        'isStudentFare': isStudentFare,
      },
    );
  }

  void _bookFlight(Map<String, dynamic> offer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.flight_takeoff, color: Colors.white),
            SizedBox(width: 8),
            Text('Redirecting to booking...'),
          ],
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
            Text(
              "Sort flights by",
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? primaryColor : darkGrey, size: 18),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: primaryColor,
                size: 16)
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
      ),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Filter by price",
                        style: TextStyle(
                          fontSize: 20,
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_currencySymbols[_selectedCurrency]}${_formatCurrency(_convertCurrency(tempMin, 'MYR', _selectedCurrency))}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${_currencySymbols[_selectedCurrency]}${_formatCurrency(_convertCurrency(tempMax, 'MYR', _selectedCurrency))}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Apply Filter",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
      final rawPrice  = double.tryParse(priceInfo['total'] as String) ?? 0.0;
      final discounted = isStudentFare ? rawPrice * 0.7 : rawPrice;
      return discounted >= _currentMinPrice && discounted <= _currentMaxPrice;
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
          final discA = isStudentFare ? priceA * 0.7 : priceA;
          final discB = isStudentFare ? priceB * 0.7 : priceB;
          final convA = _convertCurrency(discA, 'MYR', _selectedCurrency);
          final convB = _convertCurrency(discB, 'MYR', _selectedCurrency);
          return _sortAscending ? convA.compareTo(convB) : convB.compareTo(convA);

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
    return 0;
  }
}