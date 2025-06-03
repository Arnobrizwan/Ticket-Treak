// lib/screens/user/booking/seat_selection_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/models/seat_model.dart';
import 'package:ticket_trek/models/firebase_models.dart';
import 'package:ticket_trek/services/seat_service.dart';
import 'package:ticket_trek/services/firebase_booking_service.dart';
import 'package:ticket_trek/utils/seat_selection_utils.dart';

class SeatSelectionPage extends StatefulWidget {
  const SeatSelectionPage({super.key});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage>
    with TickerProviderStateMixin {
  // Violin color palette (matching FlightResultsPage)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown
  static const Color successColor    = Color(0xFF8B5000);  // Success
  static const Color warningColor    = Color(0xFFD4A373);  // Warning

  // Services
  final SeatService _seatService = SeatService();
  final FirebaseBookingService _bookingService = FirebaseBookingService();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<Seat> _allSeats = [];
  List<Seat> _filteredSeats = [];
  Map<String, String> _selectedSeats = {}; // PassengerIndex -> SeatId
  Map<SeatCategory, double> _seatPricing = {};
  SeatCategory? _selectedCategoryFilter;
  String _selectedDeck = 'Main';

  // Flight data and booking
  late Map<String, dynamic> _flightOffer;
  late String _originCode;
  late String _destinationCode;
  late String _departureDate;
  late int _adults;
  late String _travelClass;
  late bool _isStudentFare;
  late String _bookingId; // Added for Firebase integration
  FlightBooking? _currentBooking;

  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _seatController;
  late AnimationController _pulseController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _seatAnimation;
  late Animation<double> _pulseAnimation;

  // Scroll controller for seat map
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Passenger management
  int _currentPassengerIndex = 0;
  final List<String> _passengerNames = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _seatController.dispose();
    _pulseController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _seatController = AnimationController(
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
    _seatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _seatController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadingController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _flightOffer = args['offer'] as Map<String, dynamic>;
    _originCode = args['originCode'] as String;
    _destinationCode = args['destinationCode'] as String;
    _departureDate = args['departureDate'] as String;
    _adults = args['adults'] as int;
    _travelClass = args['travelClass'] as String;
    _isStudentFare = args['isStudentFare'] as bool? ?? false;

    // Check if we have an existing booking ID or need to create one
    _bookingId = args['bookingId'] as String? ?? '';

    // Initialize passenger names
    for (int i = 0; i < _adults; i++) {
      _passengerNames.add('Passenger ${i + 1}');
    }

    _initializeBooking();
  }

  Future<void> _initializeBooking() async {
    if (_bookingId.isEmpty) {
      // Create new booking first
      await _createBooking();
    } else {
      // Load existing booking
      await _loadExistingBooking();
    }
    await _loadSeatData();
  }

  Future<void> _createBooking() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final flightPrice = double.tryParse(_flightOffer['price']['total'] as String) ?? 0.0;
      final adjustedPrice = _isStudentFare ? flightPrice * 0.7 : flightPrice;

      final booking = await _bookingService.createFlightBooking(
        flightOffer: _flightOffer,
        originCode: _originCode,
        destinationCode: _destinationCode,
        departureDate: DateTime.parse(_departureDate),
        passengerCount: _adults,
        travelClass: _travelClass,
        isStudentFare: _isStudentFare,
        flightPrice: adjustedPrice,
      );

      setState(() {
        _bookingId = booking.id;
        _currentBooking = booking;
      });

      // Show booking created success message
      _showSuccessSnackBar('Booking created: ${booking.bookingReference}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create booking: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingBooking() async {
    try {
      final booking = await _bookingService.getBookingById(_bookingId);
      if (booking != null) {
        setState(() {
          _currentBooking = booking;
        });
      }
    } catch (e) {
      print('Error loading existing booking: $e');
    }
  }

  Future<void> _loadSeatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Extract flight number and aircraft type from offer
      final itineraries = _flightOffer['itineraries'] as List<dynamic>;
      final segments = itineraries[0]['segments'] as List<dynamic>;
      final firstSegment = segments[0] as Map<String, dynamic>;
      final flightNumber = '${firstSegment['carrierCode']}${firstSegment['number']}';
      const aircraftType = 'A320'; // Default for demo

      // Load seat map and pricing concurrently
      final results = await Future.wait([
        _seatService.getSeatMap(
          flightNumber: flightNumber,
          aircraftType: aircraftType,
        ),
        _seatService.getSeatPricing(
          flightNumber: flightNumber,
          departureDate: DateTime.parse(_departureDate),
        ),
      ]);

      final seats = results[0] as List<Seat>;
      final pricing = results[1] as Map<SeatCategory, double>;

      setState(() {
        _allSeats = seats;
        _filteredSeats = seats.where((seat) => seat.deck == _selectedDeck).toList();
        _seatPricing = pricing;
        _isLoading = false;
      });

      _seatController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _filterSeats() {
    setState(() {
      _filteredSeats = _allSeats.where((seat) {
        // Deck filter
        if (seat.deck != _selectedDeck) return false;

        // Category filter
        if (_selectedCategoryFilter != null && seat.category != _selectedCategoryFilter) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _selectSeat(Seat seat) {
    if (seat.status == SeatStatus.occupied) return;

    setState(() {
      // Remove previous selection for current passenger
      _selectedSeats.removeWhere((key, value) => key == _currentPassengerIndex.toString());

      // Add new selection
      _selectedSeats[_currentPassengerIndex.toString()] = seat.id;

      // Update seat status
      final seatIndex = _filteredSeats.indexWhere((s) => s.id == seat.id);
      if (seatIndex != -1) {
        _filteredSeats[seatIndex] = seat.copyWith(status: SeatStatus.selected);
      }

      // Auto-advance to next passenger if available
      if (_currentPassengerIndex < _adults - 1) {
        _currentPassengerIndex++;
      }
    });
  }

  void _autoSelectSeats() {
    final availableSeats = _filteredSeats
        .where((seat) => seat.status == SeatStatus.available)
        .map((seat) => seat.id)
        .toList();

    final recommendations = availableSeats.take(_adults).toList();


    setState(() {
      _selectedSeats.clear();

      for (int i = 0; i < recommendations.length && i < _adults; i++) {
        _selectedSeats[i.toString()] = recommendations[i];

        // Update seat status
        final seatIndex = _filteredSeats.indexWhere((s) => s.id == recommendations[i]);
        if (seatIndex != -1) {
          _filteredSeats[seatIndex] = _filteredSeats[seatIndex].copyWith(status: SeatStatus.selected);
        }
      }
    });
  }

  double _calculateTotalSeatCost() {
    double total = 0.0;
    for (final seatId in _selectedSeats.values) {
      final seat = _allSeats.firstWhere((s) => s.id == seatId);
      total += _seatPricing[seat.category] ?? 0.0;
    }
    return total;
  }

  Future<void> _proceedToAddons() async {
    // Validate seat selection
    final validation = SeatSelectionUtils.validateSeatSelection(
      selectedSeatIds: _selectedSeats.values.toList(),
      totalPassengers: _adults,
      emergencyExitSeats: _allSeats
          .where((seat) => seat.isEmergencyExit)
          .map((seat) => seat.id)
          .toList(),
      accessibilityRequirements: {},
    );

    if (!validation.isValid) {
      _showValidationDialog(validation.errors);
      return;
    }

    if (validation.hasWarnings) {
      _showWarningDialog(validation.warnings);
      return;
    }

    // Save seat selection to Firebase
    await _saveSeatSelection();
  }

  Future<void> _saveSeatSelection() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Extract flight details
      final itineraries = _flightOffer['itineraries'] as List<dynamic>;
      final segments = itineraries[0]['segments'] as List<dynamic>;
      final firstSegment = segments[0] as Map<String, dynamic>;
      final flightNumber = '${firstSegment['carrierCode']}${firstSegment['number']}';
      const aircraftType = 'A320'; // Default for demo

      final updatedBooking = await _bookingService.updateWithSeatSelection(
        bookingId: _bookingId,
        seatAssignments: _selectedSeats,
        allSeats: _allSeats,
        seatPricing: _seatPricing,
        aircraftType: aircraftType,
        flightNumber: flightNumber,
      );

      setState(() {
        _currentBooking = updatedBooking;
        _isSaving = false;
      });

      _showSuccessSnackBar('Seats saved successfully!');

      // Navigate to addon selection with updated booking
      Navigator.pushNamed(
        context,
        '/addon-selection',
        arguments: {
          'bookingId': _bookingId,
          'offer': _flightOffer,
          'selectedSeats': _selectedSeats,
          'seatCost': _calculateTotalSeatCost(),
          'originCode': _originCode,
          'destinationCode': _destinationCode,
          'departureDate': _departureDate,
          'adults': _adults,
          'travelClass': _travelClass,
          'isStudentFare': _isStudentFare,
        },
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorDialog('Failed to save seat selection: $e');
    }
  }

  void _showValidationDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Seat Selection Error',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(error, style: TextStyle(color: textColor))),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(List<String> warnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Important Notice',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: warningColor, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(warning, style: TextStyle(color: textColor))),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: darkGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSeatSelection();
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Error',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
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
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),

          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState())
          else ...[
            _buildBookingInfo(),
            _buildFlightInfo(),
            _buildPassengerSelector(),
            _buildFiltersSection(),
            _buildSeatMapLegend(),
            _buildSeatMap(),
            _buildSelectedSeatsSection(),
            _buildPricingSection(),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Select Seats',
          style: const TextStyle(
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
          child: IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            onPressed: _autoSelectSeats,
            tooltip: 'Auto Select Seats',
          ),
        ),
      ],
    );
  }

  Widget _buildBookingInfo() {
    if (_currentBooking == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [successColor.withOpacity(0.1), accentGreen.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.confirmation_number, color: successColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking: ${_currentBooking!.bookingReference}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Status: ${_currentBooking!.status.displayName}',
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
                color: successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SAVED',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlightInfo() {
    final segments = _flightOffer['itineraries'][0]['segments'] as List<dynamic>;
    final firstSegment = segments[0] as Map<String, dynamic>;
    final flightNumber = '${firstSegment['carrierCode']}${firstSegment['number']}';

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.flight, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$flightNumber • $_originCode → $_destinationCode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.parse(_departureDate)),
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
                color: successColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _travelClass,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select seats for:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _adults,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _currentPassengerIndex == index;
                  final hasSeat = _selectedSeats.containsKey(index.toString());

                  return GestureDetector(
                    onTap: () => setState(() => _currentPassengerIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(colors: [primaryColor, secondaryColor])
                            : LinearGradient(colors: [Colors.white, Colors.white]),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: hasSeat ? successColor : subtleGrey,
                          width: hasSeat ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasSeat ? Icons.check_circle : Icons.person,
                            color: isSelected ? Colors.white : (hasSeat ? successColor : darkGrey),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _passengerNames[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
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
            Text(
              'Filters & Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Deck selector
            Row(
              children: [
                Text('Deck: ', style: TextStyle(color: darkGrey, fontSize: 14)),
                ...(['Main', 'Upper'].map((deck) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(deck),
                        selected: _selectedDeck == deck,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDeck = deck;
                            });
                            _filterSeats();
                          }
                        },
                        selectedColor: primaryColor.withOpacity(0.2),
                        backgroundColor: subtleGrey.withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: _selectedDeck == deck ? primaryColor : darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))),
              ],
            ),

            const SizedBox(height: 12),

            // Category filter
            Row(
              children: [
                Text('Class: ', style: TextStyle(color: darkGrey, fontSize: 14)),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [null, ...SeatCategory.values].map((category) {
                      return ChoiceChip(
                        label: Text(category?.displayName ?? 'All'),
                        selected: _selectedCategoryFilter == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryFilter = selected ? category : null;
                          });
                          _filterSeats();
                        },
                        selectedColor: primaryColor.withOpacity(0.2),
                        backgroundColor: subtleGrey.withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: _selectedCategoryFilter == category ? primaryColor : darkGrey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatMapLegend() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: subtleGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(successColor, 'Available'),
            _buildLegendItem(primaryColor, 'Selected'),
            _buildLegendItem(darkGrey, 'Occupied'),
            _buildLegendItem(warningColor, 'Emergency'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatMap() {
    // Group seats by row
    final seatsByRow = <int, List<Seat>>{};
    for (final seat in _filteredSeats) {
      seatsByRow.putIfAbsent(seat.row, () => []).add(seat);
    }

    // Sort rows
    final sortedRows = seatsByRow.keys.toList()..sort();

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 400,
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
          children: [
            // Aircraft header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flight, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Aircraft $_selectedDeck Deck',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            // Seat map
            Expanded(
              child: Scrollbar(
                controller: _verticalScrollController,
                child: SingleChildScrollView(
                  controller: _verticalScrollController,
                  child: Scrollbar(
                    controller: _horizontalScrollController,
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: sortedRows.map((row) {
                            final rowSeats = seatsByRow[row]! 
                              ..sort((a, b) => a.column.compareTo(b.column));
                            return _buildSeatRow(row, rowSeats);
                          }).toList(),
                        ),
                      ),
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

  Widget _buildSeatRow(int row, List<Seat> seats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Row number (left)
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              '$row',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Seats in that row
          ...seats.map((seat) => _buildSeatWidget(seat)),

          const SizedBox(width: 8),

          // Row number (right)
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              '$row',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatWidget(Seat seat) {
    final isSelected = _selectedSeats.values.contains(seat.id);
    final isCurrentPassengerSeat = _selectedSeats[_currentPassengerIndex.toString()] == seat.id;

    Color seatColor;
    if (isCurrentPassengerSeat) {
      seatColor = primaryColor;
    } else if (isSelected) {
      seatColor = successColor;
    } else if (seat.status == SeatStatus.occupied) {
      seatColor = darkGrey;
    } else if (seat.isEmergencyExit) {
      seatColor = warningColor;
    } else {
      seatColor = accentGreen;
    }

    return GestureDetector(
      onTap: () => _selectSeat(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        margin: EdgeInsets.symmetric(
          horizontal: (seat.column == 'C' || seat.column == 'D') ? 8 : 2,
        ),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: isCurrentPassengerSeat
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isCurrentPassengerSeat
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            seat.column,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (seat.status == SeatStatus.occupied) ? Colors.white70 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSeatsSection() {
    if (_selectedSeats.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

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
                Icon(Icons.check_circle, color: successColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected Seats',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._selectedSeats.entries.map((entry) {
              final passengerIndex = int.parse(entry.key);
              final seatId = entry.value;
              final seat = _allSeats.firstWhere((s) => s.id == seatId);
              final price = _seatPricing[seat.category] ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        seat.column,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_passengerNames[passengerIndex]} • Seat $seatId',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          // Only display category now
                          Text(
                            seat.category.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (price > 0)
                      Text(
                        'RM ${price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: successColor,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSection() {
    final totalCost = _calculateTotalSeatCost();
    if (totalCost == 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [successColor.withOpacity(0.1), accentGreen.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: successColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seat Selection Fee',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'RM ${totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'This fee will be added to your total booking cost',
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

  Widget _buildBottomNavigation() {
    final isComplete = _selectedSeats.length == _adults;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedSeats.length} of $_adults seats selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${_calculateTotalSeatCost().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: successColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: (isComplete && !_isSaving) ? _proceedToAddons : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isComplete ? 4 : 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.save, size: 18),
                      ],
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
                  child: const Icon(Icons.airline_seat_recline_normal, color: Colors.white, size: 32),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading seat map...',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Preparing the best seats for you',
            style: TextStyle(
              fontSize: 12,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              'Unable to load seat map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Please try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSeatData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
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
}