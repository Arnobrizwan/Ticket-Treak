// lib/services/addon_service.dart

import 'dart:async';
import 'dart:math';
import 'package:ticket_trek/models/addon_model.dart';

class AddonService {
  static const Duration _simulatedDelay = Duration(milliseconds: 600);

  /// Gets available add-ons for a specific flight and route
  Future<List<FlightAddon>> getAvailableAddons({
    required String flightNumber,
    required String route,
    required String travelClass,
  }) async {
    await Future.delayed(_simulatedDelay);
    return _generateAvailableAddons(travelClass);
  }

  /// Validates add-on selections and calculates pricing
  Future<AddonValidationResult> validateAddonSelection({
    required List<String> selectedAddonIds,
    required String travelClass,
    required int passengerCount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final errors = <String>[];
    final warnings = <String>[];

    // Validate meal selections (max 1 per passenger)
    final mealAddons =
        selectedAddonIds.where((id) => id.contains('meal')).length;
    if (mealAddons > passengerCount) {
      errors.add('Cannot select more meals than passengers');
    }

    // Validate baggage combinations
    if (selectedAddonIds.contains('extra_luggage_20kg') &&
        selectedAddonIds.contains('extra_luggage_32kg')) {
      warnings.add('Consider selecting only one baggage upgrade');
    }

    return AddonValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Confirms add-on selection and processes payment
  Future<bool> confirmAddonSelection({
    required String bookingReference,
    required List<String> selectedAddonIds,
    required double totalAmount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // Simulate 97% success rate
    return Random().nextInt(100) < 97;
  }

  /// Gets popular add-ons based on analytics
  Future<List<FlightAddon>> getPopularAddons({
    required String route,
    required String travelClass,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final allAddons = _generateAvailableAddons(travelClass);
    return allAddons.where((addon) => addon.isPopular).toList();
  }

  /// Gets recommended add-ons based on passenger profile
  Future<List<FlightAddon>> getRecommendedAddons({
    required String passengerProfile,
    required String travelClass,
    required int tripDuration,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final allAddons = _generateAvailableAddons(travelClass);
    return allAddons.where((addon) => addon.isRecommended).toList();
  }

  /// Private helper to generate available add-ons
  List<FlightAddon> _generateAvailableAddons(String travelClass) {
    final addons = <FlightAddon>[];
    final random = Random();

    // Baggage add-ons
    addons.addAll([
      const FlightAddon(
        id: 'extra_luggage_20kg',
        type: AddonType.extraLuggage20kg,
        price: 80.0,
        isPopular: true,
        features: ['20kg additional weight', 'Priority handling'],
      ),
      const FlightAddon(
        id: 'extra_luggage_32kg',
        type: AddonType.extraLuggage32kg,
        price: 120.0,
        features: [
          '32kg additional weight',
          'Priority handling',
          'Fragile tag'
        ],
      ),
      const FlightAddon(
        id: 'sports_equipment',
        type: AddonType.sportsEquipment,
        price: 95.0,
        features: ['Special handling', 'Insurance coverage'],
      ),
    ]);

    // Meal add-ons
    addons.addAll([
      const FlightAddon(
        id: 'vegetarian_meal',
        type: AddonType.vegetarianMeal,
        price: 25.0,
        isPopular: true,
        isRecommended: true,
        features: ['Fresh ingredients', 'Nutritionally balanced'],
      ),
      const FlightAddon(
        id: 'halal_meal',
        type: AddonType.halalMeal,
        price: 25.0,
        features: ['Certified halal', 'Traditional flavors'],
      ),
      const FlightAddon(
        id: 'kosher_meal',
        type: AddonType.kosherMeal,
        price: 30.0,
        features: ['Kosher certified', 'Traditional preparation'],
      ),
      FlightAddon(
        id: 'premium_meal',
        type: AddonType.premiumMeal,
        price: 65.0,
        isRecommended: travelClass.toLowerCase() == 'economy',
        features: ['Chef-prepared', '3-course meal', 'Premium ingredients'],
      ),
      const FlightAddon(
        id: 'child_meal',
        type: AddonType.childMeal,
        price: 20.0,
        features: ['Kid-friendly', 'Healthy options', 'Fun presentation'],
      ),
    ]);

    // Service add-ons
    addons.addAll([
      const FlightAddon(
        id: 'priority_boarding',
        type: AddonType.priorityBoarding,
        price: 25.0,
        isPopular: true,
        features: ['Board first', 'Overhead space guaranteed'],
      ),
      const FlightAddon(
        id: 'lounge_access',
        type: AddonType.loungeAccess,
        price: 65.0,
        isRecommended: true,
        features: [
          'Complimentary drinks',
          'WiFi access',
          'Comfortable seating'
        ],
      ),
      const FlightAddon(
        id: 'fast_track_security',
        type: AddonType.fastTrackSecurity,
        price: 30.0,
        features: ['Skip queues', 'Dedicated lanes'],
      ),
      const FlightAddon(
        id: 'meet_and_greet',
        type: AddonType.meetAndGreet,
        price: 85.0,
        features: [
          'Personal assistant',
          'Baggage handling',
          'Check-in assistance'
        ],
      ),
    ]);

    // Entertainment add-ons
    addons.addAll([
      const FlightAddon(
        id: 'wifi',
        type: AddonType.wifi,
        price: 15.0,
        isPopular: true,
        features: ['Unlimited data', 'High-speed connection'],
      ),
      const FlightAddon(
        id: 'entertainment',
        type: AddonType.entertainment,
        price: 12.0,
        features: ['Latest movies', 'Music collection', 'Games'],
      ),
    ]);

    // Insurance add-ons
    addons.addAll([
      const FlightAddon(
        id: 'travel_insurance',
        type: AddonType.travelInsurance,
        price: 45.0,
        isRecommended: true,
        features: ['Medical coverage', 'Trip interruption', '24/7 support'],
      ),
      const FlightAddon(
        id: 'cancellation_cover',
        type: AddonType.cancellationCover,
        price: 35.0,
        features: ['Flexible cancellation', 'Refund guarantee'],
      ),
    ]);

    // Apply dynamic pricing (0.8× to 1.2× random multiplier)
    return addons.map((addon) {
      final priceMultiplier = 0.8 + (random.nextDouble() * 0.4);
      return addon.copyWith(price: addon.price * priceMultiplier);
    }).toList();
  }
}

class AddonValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const AddonValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
