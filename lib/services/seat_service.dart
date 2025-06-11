import 'dart:async';
import 'dart:math';
import 'package:ticket_trek/models/seat_model.dart';

class SeatService {
  static const Duration _simulatedDelay = Duration(milliseconds: 800);
  
  /// Simulates fetching seat map data from an airline API
  Future<List<Seat>> getSeatMap({
    required String flightNumber,
    required String aircraftType,
  }) async {
    // Simulate API delay
    await Future.delayed(_simulatedDelay);
    
    // Generate realistic seat map based on aircraft type
    return _generateSeatMap(aircraftType);
  }

  /// Updates seat selection on the server
  Future<bool> updateSeatSelection({
    required String flightNumber,
    required Map<String, String> seatAssignments,
  }) async {
    await Future.delayed(_simulatedDelay);
    // Simulate 95% success rate
    return Random().nextInt(100) < 95;
  }

  /// Checks if seat is still available before final confirmation
  Future<bool> confirmSeatAvailability(String seatId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulate 98% availability
    return Random().nextInt(100) < 98;
  }

  /// Gets real-time seat pricing based on demand
  Future<Map<SeatCategory, double>> getSeatPricing({
    required String flightNumber,
    required DateTime departureDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate dynamic pricing
    final baseMultiplier = _getDemandMultiplier(departureDate);
    return {
      SeatCategory.economy: 0.0,
      SeatCategory.premiumEconomy: 45.0 * baseMultiplier,
      SeatCategory.business: 150.0 * baseMultiplier,
      SeatCategory.first: 300.0 * baseMultiplier,
      SeatCategory.emergencyExit: 25.0 * baseMultiplier,
    };
  }

  /// Private helper to generate realistic seat map
  List<Seat> _generateSeatMap(String aircraftType) {
    final seats = <Seat>[];
    switch (aircraftType.toLowerCase()) {
      case 'a320':
        seats.addAll(_generateA320SeatMap());
        break;
      case 'b737':
        seats.addAll(_generateB737SeatMap());
        break;
      case 'a380':
        seats.addAll(_generateA380SeatMap());
        break;
      default:
        seats.addAll(_generateDefaultSeatMap());
    }
    return seats;
  }

  List<Seat> _generateA320SeatMap() {
    final seats = <Seat>[];
    final random = Random();
    
    // First Class (Rows 1-3)
    for (int row = 1; row <= 3; row++) {
      for (String col in ['A', 'B', 'C', 'D']) {
        final seatId = '$row$col';
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 7 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.first,
        ));
      }
    }
    
    // Business Class (Rows 4-8)
    for (int row = 4; row <= 8; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F']) {
        final seatId = '$row$col';
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 6 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.business,
        ));
      }
    }
    
    // Premium Economy (Rows 9-12)
    for (int row = 9; row <= 12; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F']) {
        final seatId = '$row$col';
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 8 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.premiumEconomy,
        ));
      }
    }
    
    // Emergency Exit Rows (13, 14)
    for (int row = 13; row <= 14; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F']) {
        final seatId = '$row$col';
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 9 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.emergencyExit,
          isEmergencyExit: true,
        ));
      }
    }
    
    // Economy Class (Rows 15-45)
    for (int row = 15; row <= 45; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F']) {
        final seatId = '$row$col';
        final hasAccessibility = row == 20 && (col == 'A' || col == 'F');
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 7 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.economy,
          hasAccessibility: hasAccessibility,
        ));
      }
    }
    
    return seats;
  }

  List<Seat> _generateB737SeatMap() {
    // For simplicity, use the same as A320
    return _generateA320SeatMap();
  }

  List<Seat> _generateA380SeatMap() {
    final seats = <Seat>[];
    final random = Random();
    
    // Main Deck, rows 1-60
    for (int row = 1; row <= 60; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K']) {
        final seatId = '$row$col';
        SeatCategory category;
        if (row <= 5) {
          category = SeatCategory.first;
        } else if (row <= 15) {
          category = SeatCategory.business;
        } else if (row <= 25) {
          category = SeatCategory.premiumEconomy;
        } else {
          category = SeatCategory.economy;
        }
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 7 ? SeatStatus.available : SeatStatus.occupied,
          category: category,
          deck: 'Main',
        ));
      }
    }
    
    // Upper Deck, rows 70-90
    for (int row = 70; row <= 90; row++) {
      for (String col in ['A', 'B', 'C', 'D', 'E', 'F']) {
        final seatId = '$row$col';
        seats.add(Seat(
          id: seatId,
          row: row,
          column: col,
          status: random.nextInt(10) < 8 ? SeatStatus.available : SeatStatus.occupied,
          category: SeatCategory.business,
          deck: 'Upper',
        ));
      }
    }
    
    return seats;
  }

  List<Seat> _generateDefaultSeatMap() {
    return _generateA320SeatMap();
  }

  double _getDemandMultiplier(DateTime departureDate) {
    final daysUntilDeparture = departureDate.difference(DateTime.now()).inDays;
    if (daysUntilDeparture <= 1) {
      return 1.5; // High demand
    } else if (daysUntilDeparture <= 7) {
      return 1.2;
    } else if (daysUntilDeparture <= 30) {
      return 1.0;
    } else {
      return 0.8; // Early booking discount
    }
  }
}