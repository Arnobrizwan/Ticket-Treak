// lib/screens/user/booking/addon_selection_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ticket_trek/routes/app_routes.dart';
import 'package:ticket_trek/models/addon_model.dart';
import 'package:ticket_trek/models/firebase_models.dart';
import 'package:ticket_trek/services/addon_service.dart';
import 'package:ticket_trek/services/firebase_booking_service.dart';

class AddonSelectionPage extends StatefulWidget {
  const AddonSelectionPage({super.key});

  @override
  State<AddonSelectionPage> createState() => _AddonSelectionPageState();
}

class _AddonSelectionPageState extends State<AddonSelectionPage>
    with TickerProviderStateMixin {
  // Violin color palette (matching FlightResultsPage)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
  static const Color textColor = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E); // Muted Brown
  static const Color successColor = Color(0xFF8B5000); // Success
  static const Color warningColor = Color(0xFFD4A373); // Warning

  // Services
  final AddonService _addonService = AddonService();
  final FirebaseBookingService _bookingService = FirebaseBookingService();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<FlightAddon> _allAddons = [];
  List<FlightAddon> _popularAddons = [];
  List<FlightAddon> _recommendedAddons = [];
  AddonSelection _addonSelection = const AddonSelection();
  AddonCategory? _selectedCategory;

  // Flight data and booking (from Firebase)
  late String _bookingId;
  FlightBooking? _currentBooking;
  late Map<String, dynamic> _flightOffer;
  late Map<String, String> _selectedSeats;
  late double _seatCost;
  late String _originCode;
  late String _destinationCode;
  late String _departureDate;
  late int _adults;
  late String _travelClass;
  late bool _isStudentFare;

  // Animation controllers
  late AnimationController _loadingController;
  late AnimationController _addonController;
  late AnimationController _pulseController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _addonAnimation;
  late Animation<double> _pulseAnimation;

  // UI State
  final ScrollController _scrollController = ScrollController();
  bool _showRecommendations = true;
  bool _showPopular = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _addonController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _addonController = AnimationController(
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
    _addonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _addonController, curve: Curves.elasticOut),
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
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Get booking ID and other data
    final bookingIdArg = args['bookingId'] as String?;
    if (bookingIdArg == null || bookingIdArg.isEmpty) {
      throw FlutterError(
          'Invalid or missing bookingId argument: $bookingIdArg');
    }
    _bookingId = bookingIdArg;
    _flightOffer = args['offer'] as Map<String, dynamic>;
    _selectedSeats = Map<String, String>.from(args['selectedSeats'] as Map);
    _seatCost = args['seatCost'] as double;
    _originCode = args['originCode'] as String;
    _destinationCode = args['destinationCode'] as String;
    _departureDate = args['departureDate'] as String;
    _adults = args['adults'] as int;
    _travelClass = args['travelClass'] as String;
    _isStudentFare = args['isStudentFare'] as bool? ?? false;

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadBookingData();
    await _loadAddonData();
  }

  Future<void> _loadBookingData() async {
    if (_bookingId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid booking ID. Cannot load booking data.';
      });
      return;
    }
    try {
      final booking = await _bookingService.getBookingById(_bookingId);
      if (booking != null) {
        setState(() {
          _currentBooking = booking;
        });
      }
    } catch (e) {
      print('Error loading booking data: $e');
    }
  }

  Future<void> _loadAddonData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Extract flight details
      final segments =
          _flightOffer['itineraries'][0]['segments'] as List<dynamic>;
      final firstSegment = segments[0] as Map<String, dynamic>;
      final flightNumber =
          '${firstSegment['carrierCode']}${firstSegment['number']}';
      final route = '$_originCode-$_destinationCode';

      // Load all addon data concurrently
      final results = await Future.wait([
        _addonService.getAvailableAddons(
          flightNumber: flightNumber,
          route: route,
          travelClass: _travelClass,
        ),
        _addonService.getPopularAddons(
          route: route,
          travelClass: _travelClass,
        ),
        _addonService.getRecommendedAddons(
          passengerProfile: 'standard',
          travelClass: _travelClass,
          tripDuration: 1,
        ),
      ]);

      final allAddons = results[0];
      final popularAddons = results[1];
      final recommendedAddons = results[2];

      setState(() {
        _allAddons = allAddons;
        _popularAddons = popularAddons;
        _recommendedAddons = recommendedAddons;
        _isLoading = false;
      });

      _addonController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _toggleAddon(FlightAddon addon) {
    setState(() {
      if (_addonSelection.hasAddon(addon.id)) {
        _addonSelection = _addonSelection.removeAddon(addon.id);
      } else {
        _addonSelection = _addonSelection.addAddon(addon);
      }
    });
  }

  void _addRecommendedAddons() {
    setState(() {
      for (final addon in _recommendedAddons) {
        if (!_addonSelection.hasAddon(addon.id)) {
          _addonSelection = _addonSelection.addAddon(addon);
        }
      }
    });
  }

  void _clearAllAddons() {
    setState(() {
      _addonSelection = const AddonSelection();
    });
  }

  Future<void> _validateAndProceed() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: backgroundColor,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text(
                'Validating and saving selections...',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final validation = await _addonService.validateAddonSelection(
        selectedAddonIds: _addonSelection.selectedAddons.keys.toList(),
        travelClass: _travelClass,
        passengerCount: _adults,
      );

      Navigator.pop(context); // Close loading dialog

      if (!validation.isValid) {
        _showValidationDialog(validation.errors, validation.warnings);
        return;
      }

      if (validation.hasWarnings) {
        _showWarningDialog(validation.warnings);
        return;
      }

      await _saveAddonSelection(validation);
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Validation failed: $e');
    }
  }

  Future<void> _saveAddonSelection(AddonValidationResult validation) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare validation result for storage
      final validationResult = {
        'isValid': validation.isValid,
        'errors': validation.errors,
        'warnings': validation.warnings,
        'validatedAt': DateTime.now().toIso8601String(),
      };

      final updatedBooking = await _bookingService.updateWithAddonSelection(
        bookingId: _bookingId,
        addonSelection: _addonSelection,
        validationResult: validationResult,
      );

      setState(() {
        _currentBooking = updatedBooking;
        _isSaving = false;
      });

      _showSuccessSnackBar('Add-ons saved successfully!');

      // Navigate to booking summary/confirmation
      Navigator.pushNamed(
        context,
        AppRoutes.passengerDetails,
        arguments: {
          'adults': _adults, // <— number of passengers (required)
          'bookingId': _bookingId, // optional—you can still pass this if needed
          'flightOffer': _flightOffer, // pass your entire flightOffer Map
          'selectedSeats': _selectedSeats, // pass the seat selection map
          'seatCost': _seatCost, // pass seat cost
          'originCode': _originCode,
          'destinationCode': _destinationCode,
          'departureDate': _departureDate,
          'travelClass': _travelClass,
          'isStudentFare': _isStudentFare,
          'addOns': _addonSelection.selectedAddons.keys.toList(),
          //'booking': updatedBooking,
        },
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorDialog('Failed to save add-on selection: $e');
    }
  }

  void _showValidationDialog(List<String> errors, List<String> warnings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Selection Issues',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errors.isNotEmpty) ...[
                const Text(
                  'Errors:',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                ...errors.map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(error,
                                  style: const TextStyle(color: textColor))),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              if (warnings.isNotEmpty) ...[
                const Text(
                  'Warnings:',
                  style: TextStyle(
                      color: warningColor, fontWeight: FontWeight.bold),
                ),
                ...warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber,
                              color: warningColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(warning,
                                  style: const TextStyle(color: textColor))),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: primaryColor)),
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
        title: const Text(
          'Please Confirm',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: warnings
                .map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: accentOrange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(warning,
                                  style: const TextStyle(color: textColor))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back', style: TextStyle(color: darkGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final validation = AddonValidationResult(
                isValid: true,
                errors: [],
                warnings: warnings,
              );
              await _saveAddonSelection(validation);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child:
                const Text('Continue', style: TextStyle(color: Colors.white)),
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
        title: const Text(
          'Error',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: primaryColor)),
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
            const Icon(Icons.check_circle, color: Colors.white),
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

  List<FlightAddon> _getAddonsByCategory(AddonCategory category) {
    return _allAddons
        .where((addon) => addon.type.category == category)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            SliverFillRemaining(child: _buildLoadingState())
          else if (_errorMessage != null)
            SliverFillRemaining(child: _buildErrorState())
          else ...[
            _buildBookingStatus(),
            _buildBookingSummary(),
            if (_showRecommendations && _recommendedAddons.isNotEmpty)
              _buildRecommendedSection(),
            if (_showPopular && _popularAddons.isNotEmpty)
              _buildPopularSection(),
            _buildCategoryFilters(),
            _buildAddonCategories(),
            _buildSelectedAddonsSection(),
          ],
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  /// ─── AppBar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Add-ons & Services',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
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
        if (_addonSelection.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white, size: 20),
              onPressed: _clearAllAddons,
              tooltip: 'Clear All',
            ),
          ),
      ],
    );
  }

  /// ─── Booking Status Card ─────────────────────────────────────────────────
  Widget _buildBookingStatus() {
    if (_currentBooking == null)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              successColor.withOpacity(0.1),
              accentGreen.withOpacity(0.1)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: successColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: successColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking: ${_currentBooking!.bookingReference}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Status: ${_currentBooking!.status.displayName}',
                    style: const TextStyle(
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
              child: const Text(
                'SAVED',
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
    );
  }

  /// ─── Booking Summary Card ─────────────────────────────────────────────────
  Widget _buildBookingSummary() {
    final flightPrice = _currentBooking?.flightPrice ??
        (double.tryParse(_flightOffer['price']['total'] as String) ?? 0.0);
    final seatCost = _currentBooking?.seatBooking?.totalSeatCost ?? _seatCost;
    final totalBase = flightPrice + seatCost;

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
                  child: const Icon(Icons.receipt_long,
                      color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '$_originCode → $_destinationCode • ${_selectedSeats.length} seat${_selectedSeats.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Flight Cost', style: TextStyle(color: darkGrey)),
                Text('RM ${flightPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: textColor, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seat Selection', style: TextStyle(color: darkGrey)),
                Text('RM ${seatCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: textColor, fontWeight: FontWeight.w600)),
              ],
            ),
            if (_addonSelection.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add-ons', style: TextStyle(color: darkGrey)),
                  Text('RM ${_addonSelection.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: successColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'RM ${(totalBase + _addonSelection.totalPrice).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Recommended Section ───────────────────────────────────────────────────
  Widget _buildRecommendedSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars, color: accentOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recommended for You',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _addRecommendedAddons,
                      child: const Text(
                        'Add All',
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                          () => _showRecommendations = !_showRecommendations),
                      icon: Icon(
                        _showRecommendations
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_showRecommendations) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 220, // Increased height to prevent overflow
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _recommendedAddons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildAddonCard(
                      _recommendedAddons[index],
                      isRecommended: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ─── Popular Section ───────────────────────────────────────────────────────
  Widget _buildPopularSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: successColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Popular Choices',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _showPopular = !_showPopular),
                  icon: Icon(
                    _showPopular ? Icons.expand_less : Icons.expand_more,
                    color: darkGrey,
                  ),
                ),
              ],
            ),
            if (_showPopular) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 200, // Increased height to prevent overflow
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _popularAddons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _buildAddonCard(_popularAddons[index], isPopular: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ─── Category Filters (Chips) ──────────────────────────────────────────────
  Widget _buildCategoryFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AddonCategory.values.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCategoryChip(null, 'All', Icons.grid_view);
                  }
                  final category = AddonCategory.values[index - 1];
                  return _buildCategoryChip(
                    category,
                    _getCategoryDisplayName(category),
                    _getCategoryIcon(category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
      AddonCategory? category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [primaryColor, secondaryColor])
              : const LinearGradient(colors: [Colors.white, Colors.white]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : subtleGrey,
            width: isSelected ? 2 : 1,
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
            Icon(icon, color: isSelected ? Colors.white : darkGrey, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
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
  }

  /// ─── Addon Categories (Full Grid) ─────────────────────────────────────────
  Widget _buildAddonCategories() {
    final categoriesToShow =
        _selectedCategory != null ? [_selectedCategory!] : AddonCategory.values;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = categoriesToShow[index];
          final addons = _getAddonsByCategory(category);

          if (addons.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getCategoryIcon(category),
                        color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryDisplayName(category),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75, // Adjusted ratio
                  ),
                  itemCount: addons.length,
                  itemBuilder: (context, index) =>
                      _buildAddonCard(addons[index]),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
        childCount: categoriesToShow.length,
      ),
    );
  }

  /// ─── FIXED: Single "Card" for One Add-on ──────────────────────────────────
  Widget _buildAddonCard(FlightAddon addon,
      {bool isRecommended = false, bool isPopular = false}) {
    final isSelected = _addonSelection.hasAddon(addon.id);
    final isHorizontal = isRecommended || isPopular;

    return GestureDetector(
      onTap: () => _toggleAddon(addon),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isHorizontal ? 170 : null, // Fixed width for horizontal cards
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : subtleGrey.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  // Header with image and badges
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          addon.type.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoryIcon(addon.type.category),
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentOrange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Rec',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: successColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Pop',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Title - Fixed height to prevent overflow
                  SizedBox(
                    height: 32, // Fixed height for title
                    child: Text(
                      addon.type.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Description - Fixed height
                  SizedBox(
                    height: isHorizontal ? 32 : 28, // Adjust for layout
                    child: Text(
                      addon.type.description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: darkGrey,
                      ),
                      maxLines: isHorizontal ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Features - Limited to 1 line for horizontal cards
                  if (addon.features.isNotEmpty)
                    SizedBox(
                      height: isHorizontal ? 16 : 24,
                      child: Text(
                        isHorizontal
                            ? '• ${addon.features.first}'
                            : '• ${addon.features.take(2).join('\n• ')}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: accentGreen,
                        ),
                        maxLines: isHorizontal ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Spacer to push price to bottom
                  if (!isHorizontal) const Spacer(),
                  if (isHorizontal) const SizedBox(height: 8),

                  // Price and button - Fixed at bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'RM ${addon.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: successColor,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor
                              : subtleGrey.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check : Icons.add,
                          color: isSelected ? Colors.white : darkGrey,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection overlay
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ─── Selected Add-ons Section ────────────────────────────────────────────
  Widget _buildSelectedAddonsSection() {
    if (_addonSelection.isEmpty) {
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
                const Icon(Icons.shopping_cart, color: successColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Selected Add-ons (${_addonSelection.count})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._addonSelection.addons
                .map((addon) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              addon.type.imageUrl,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  _getCategoryIcon(addon.type.category),
                                  color: primaryColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addon.type.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getCategoryDisplayName(addon.type.category),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: darkGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'RM ${addon.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: successColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _toggleAddon(addon),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add-ons Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  'RM ${_addonSelection.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(AddonCategory category) {
    switch (category) {
      case AddonCategory.baggage:
        return 'Baggage';
      case AddonCategory.meals:
        return 'Meals';
      case AddonCategory.services:
        return 'Services';
      case AddonCategory.entertainment:
        return 'Entertainment';
      case AddonCategory.insurance:
        return 'Insurance';
    }
  }

  IconData _getCategoryIcon(AddonCategory category) {
    switch (category) {
      case AddonCategory.baggage:
        return Icons.luggage;
      case AddonCategory.meals:
        return Icons.restaurant;
      case AddonCategory.services:
        return Icons.room_service;
      case AddonCategory.entertainment:
        return Icons.tv;
      case AddonCategory.insurance:
        return Icons.security;
    }
  }

  /// ─── Bottom Navigation Bar (Totals + Save) ───────────────────────────────
  Widget _buildBottomNavigation() {
    final flightPrice = _currentBooking?.flightPrice ??
        (double.tryParse(_flightOffer['price']['total'] as String) ?? 0.0);
    final seatCost = _currentBooking?.seatBooking?.totalSeatCost ?? _seatCost;
    final totalCost = flightPrice + seatCost + _addonSelection.totalPrice;

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
                  const Text(
                    'Total Cost',
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: successColor,
                    ),
                  ),
                  if (_addonSelection.isNotEmpty)
                    Text(
                      '+${_addonSelection.count} add-on${_addonSelection.count > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: darkGrey,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: !_isSaving ? _validateAndProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
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
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.save, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ─── Loading Placeholder ──────────────────────────────────────────────────
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
                    gradient: const LinearGradient(
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
                  child: const Icon(Icons.add_shopping_cart,
                      color: Colors.white, size: 32),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading available add-ons...',
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Finding the best services for your journey',
            style: TextStyle(
              fontSize: 12,
              color: darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  /// ─── Error Placeholder ────────────────────────────────────────────────────
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
              child: Icon(Icons.error_outline,
                  size: 56, color: Colors.red.shade700),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to load add-ons',
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
              style: const TextStyle(
                fontSize: 14,
                color: darkGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAddonData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
