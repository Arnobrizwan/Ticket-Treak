// lib/screens/user/flight/flight_results_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/services/amadeus_service.dart';

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({super.key});

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  // Violin color palette (matching FlightSearchPage)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor      = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor    = Color(0xFF8B5000); // Amber Brown
  static const Color textColor         = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey        = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey          = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange      = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen       = Color(0xFFB28F5E); // Muted Brown

  bool _isLoading = true;
  String? _errorMessage;

  /// We keep both an “all offers” list (unfiltered) and a “displayed” list:
  List<dynamic> _allFlightOffers = [];
  List<dynamic> _displayedOffers = [];

  /// Price‐filter state:
  double _minPriceFilter = 0.0;   // absolute minimum price in the fetched results
  double _maxPriceFilter = 0.0;   // absolute maximum price in the fetched results
  double _currentMinPrice = 0.0;  // current slider minimum
  double _currentMaxPrice = 0.0;  // current slider maximum

  /// Sort‐by‐duration toggle:
  bool _sortAscending = true;

  /// Navigator arguments (populated in didChangeDependencies):
  late final String originCode;
  late final String destinationCode;
  late final String departureDateStr;
  late final int    adults;
  late final String travelClass; // e.g. "ECONOMY" or "BUSINESS"
  late final bool   direct;
  late final bool   isStudentFare;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1) Read arguments from Navigator
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    originCode       = args['originCode']       as String;
    destinationCode  = args['destinationCode']  as String;
    departureDateStr = args['departureDate']    as String; // "yyyy-MM-dd"
    adults           = args['adults']           as int;
    travelClass      = args['travelClass']      as String; // already uppercase
    direct           = args['direct']           as bool;
    isStudentFare    = args['isStudentFare']    as bool;

    // 2) Kick off the API call:
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
        originCode      : originCode,
        destinationCode : destinationCode,
        departureDate   : departureDateStr,
        direct          : direct,
        adults          : adults,
        travelClass     : travelClass,
      );

      // After we fetch “results”, also compute min/max price for filtering:
      double lowest = double.infinity;
      double highest = 0.0;

      for (final offer in results) {
        final priceInfo = offer['price'] as Map<String, dynamic>;
        final totalPriceStr = priceInfo['total'] as String;
        final priceValue = double.tryParse(totalPriceStr) ?? 0.0;
        if (priceValue < lowest) lowest = priceValue;
        if (priceValue > highest) highest = priceValue;
      }

      // If no valid price found, set defaults to 0
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
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Flights: $originCode → $destinationCode",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          // 1) Filter button
          IconButton(
            icon: const Icon(Icons.filter_list, size: 28),
            tooltip: "Filter by Price",
            onPressed: _displayedOffers.isEmpty
                ? null
                : () => _showPriceFilterSheet(context),
          ),
          // 2) Sort button
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined,
              size: 28,
            ),
            tooltip: "Sort by Duration",
            onPressed: _displayedOffers.isEmpty
                ? null
                : _toggleSortByDuration,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : (_errorMessage != null
              ? _buildErrorState(_errorMessage!)
              : _displayedOffers.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList()),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// LOADING STATE
  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// ERROR STATE
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            Text(
              "Error fetching flights:\n$message",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchFlightOffers,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Retry",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// EMPTY STATE (No offers to show)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airplane_ticket, size: 48, color: subtleGrey),
            const SizedBox(height: 16),
            const Text(
              "No flights match your filters.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Return to previous screen to modify search
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Modify Search",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// RESULTS LIST (After successful API call & filtering)
  Widget _buildResultsList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _displayedOffers.length,
      itemBuilder: (context, index) {
        final offer = _displayedOffers[index] as Map<String, dynamic>;
        return _buildOfferCard(offer, index);
      },
    );
  }

  /// ────────────────────────────────────────────────────────────────
  /// SINGLE FLIGHT OFFER CARD
  Widget _buildOfferCard(Map<String, dynamic> offer, int index) {
    // 1) Parse total price & currency:
    final priceInfo   = offer['price'] as Map<String, dynamic>;
    final totalPrice  = priceInfo['total'] as String;    // e.g. "250.00"
    final currency    = priceInfo['currency'] as String; // e.g. "MYR"
    final priceValue  = double.tryParse(totalPrice) ?? 0.0;

    // 2) Parse the first itinerary (most offers only have one):
    final itineraries = offer['itineraries'] as List<dynamic>;
    final firstItin   = (itineraries[0] as Map<String, dynamic>);
    final durationStr = firstItin['duration'] as String; // e.g. "PT2H45M"
    final segments    = firstItin['segments'] as List<dynamic>;

    // 3) For simplicity, show only the very first segment:
    final firstSeg    = (segments[0] as Map<String, dynamic>);
    final dep         = firstSeg['departure'] as Map<String, dynamic>;
    final arr         = firstSeg['arrival'] as Map<String, dynamic>;
    final carrier     = firstSeg['carrierCode'] as String; // e.g. "MH"
    final flightNo    = firstSeg['number'] as String;      // e.g. "1268"
    DateTime depAt     = DateTime.parse(dep['at'] as String);
    DateTime arrAt     = DateTime.parse(arr['at'] as String);

    // 4) Format times:
    final depTimeFmt = DateFormat('hh:mm a').format(depAt);
    final arrTimeFmt = DateFormat('hh:mm a').format(arrAt);
    final depDateFmt = DateFormat('MMM dd').format(depAt);
    final arrDateFmt = DateFormat('MMM dd').format(arrAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top strip: OFFER NUMBER
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft : Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              "Offer #${index + 1}",
              style: TextStyle(
                color: accentOrange.darken(0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Main content: departure‐arrival info + price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Row: Carrier → Flight No. → Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // (You could replace this with an airline logo in a real app)
                        CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.2),
                          child: Text(
                            carrier,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$carrier $flightNo",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "$currency $totalPrice",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Row: Departure info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Departure time & date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depTimeFmt,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$originCode • $depDateFmt",
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                      ],
                    ),

                    // Flight duration / icon
                    Column(
                      children: [
                        Icon(Icons.schedule, color: primaryColor, size: 20),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(durationStr),
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Arrival time & date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrTimeFmt,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$destinationCode • $arrDateFmt",
                          style: TextStyle(
                            fontSize: 12,
                            color: darkGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // “Book Now” / “Select” button (placeholder)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // In a real app you’d push to a “Booking Details” screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Proceed to booking…'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Select",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
  /// Converts ISO-8601 “PT#H#M” → “2h 45m”, etc.
  String _formatDuration(String isoDuration) {
    // Example input: "PT2H45M"
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours   = match.group(1)!;
      final minutes = match.group(2)!;
      return "${hours}h ${minutes}m";
    }
    return isoDuration.replaceFirst("PT", "").replaceAll("H", "h ").replaceAll("M", "m");
  }

  //─────────────────────────────────────────────────────────────────────────────
  // PRICE FILTER SHEET
  void _showPriceFilterSheet(BuildContext context) {
    double tempMin = _currentMinPrice;
    double tempMax = _currentMaxPrice;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter by Price",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: darkGrey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Display current range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_currencyFormat(tempMin)}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${_currencyFormat(tempMax)}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // RangeSlider
                  RangeSlider(
                    min: _minPriceFilter,
                    max: _maxPriceFilter,
                    divisions: (_maxPriceFilter - _minPriceFilter).round().clamp(1, 100),
                    values: RangeValues(tempMin, tempMax),
                    labels: RangeLabels(
                      _currencyFormat(tempMin),
                      _currencyFormat(tempMax),
                    ),
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

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 1) Update current slider values
                        setState(() {
                          _currentMinPrice = tempMin;
                          _currentMaxPrice = tempMax;
                        });

                        // 2) Filter the “all” list and then re-sort
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

  /// Filter `_allFlightOffers` by price range [_currentMinPrice.._currentMaxPrice],
  /// then re‐sort according to `_sortAscending`, and push results into `_displayedOffers`.
  void _applyPriceFilterAndSort() {
    final filtered = _allFlightOffers.where((offer) {
      final priceInfo  = offer['price'] as Map<String, dynamic>;
      final totalPrice = double.tryParse(priceInfo['total'] as String) ?? 0.0;
      return totalPrice >= _currentMinPrice && totalPrice <= _currentMaxPrice;
    }).toList();

    setState(() {
      _displayedOffers = filtered;
    });

    // Finally, re‐apply sorting on the newly filtered list:
    _sortDisplayedOffers();
  }

  /// Called when user taps the “Sort” button:
  /// toggles ascending/descending, then re‐sorts.
  void _toggleSortByDuration() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
    _sortDisplayedOffers();
  }

  /// Sort `_displayedOffers` by total itinerary duration (first itinerary),
  /// in ascending or descending order depending on `_sortAscending`.
  void _sortDisplayedOffers() {
    _displayedOffers.sort((a, b) {
      final itinA   = (a['itineraries'][0] as Map<String, dynamic>);
      final itinB   = (b['itineraries'][0] as Map<String, dynamic>);
      final durA    = _parseDurationToMinutes(itinA['duration'] as String);
      final durB    = _parseDurationToMinutes(itinB['duration'] as String);
      return _sortAscending ? durA.compareTo(durB) : durB.compareTo(durA);
    });
    setState(() { /* refresh */ });
  }

  /// Helper: “PT2H45M” → 165 (minutes)
  int _parseDurationToMinutes(String isoDuration) {
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours   = int.tryParse(match.group(1)!)   ?? 0;
      final minutes = int.tryParse(match.group(2)!)   ?? 0;
      return hours * 60 + minutes;
    }
    // fallback: strip non-digits
    return int.tryParse(isoDuration.replaceAll(RegExp(r'\D+'), '')) ?? 0;
  }

  /// Format a double as “MYR xxx.xx”
  String _currencyFormat(double value) {
    return NumberFormat.simpleCurrency(name: "").format(value);
  }
}

/// ────────────────────────────────────────────────────────────────
/// Minor extension to darken a Color (used for the “Offer #” label).
extension ColorExtension on Color {
  /// Darken the color by [amount] between 0.0 and 1.0
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}