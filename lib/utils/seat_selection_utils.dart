// lib/utils/seat_selection_utils.dart

/// A simple result object for seat-validation
class SeatSelectionValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const SeatSelectionValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    return 'SeatSelectionValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}

class SeatSelectionUtils {
  /// Validates that:
  ///  • exactly `totalPassengers` seats have been chosen,
  ///  • no duplicates,
  ///  • emergency-exit seats yield a warning,
  ///  • accessibility requirements yield a warning,
  ///  • group seats are adjacent (if more than one passenger) or else warn.
  static SeatSelectionValidationResult validateSeatSelection({
    required List<String> selectedSeatIds,
    required int totalPassengers,
    required List<String> emergencyExitSeats,
    required Map<String, bool> accessibilityRequirements,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1) Check count
    if (selectedSeatIds.length != totalPassengers) {
      if (selectedSeatIds.length < totalPassengers) {
        errors.add(
          'Not all passengers have assigned seats '
          '(${selectedSeatIds.length}/$totalPassengers selected)',
        );
      } else {
        errors.add(
          'Too many seats selected '
          '(${selectedSeatIds.length}/$totalPassengers expected)',
        );
      }
    }

    // 2) Duplicates?
    final uniqueSeats = selectedSeatIds.toSet();
    if (uniqueSeats.length != selectedSeatIds.length) {
      errors.add('Duplicate seat assignments detected');
    }

    // 3) Emergency-exit warning
    final selectedEmergencySeats = selectedSeatIds
        .where((seatId) => emergencyExitSeats.contains(seatId))
        .toList();
    if (selectedEmergencySeats.isNotEmpty) {
      warnings.add(
        'Emergency exit seats require passenger acknowledgment '
        'of safety responsibilities',
      );
      warnings.add(
        'Passengers must be physically able to assist in emergency evacuation',
      );
    }

    // 4) Accessibility requirements
    if (accessibilityRequirements.containsValue(true)) {
      final hasAccessibilitySeat = selectedSeatIds.any(_isAccessibilitySeat);
      if (!hasAccessibilitySeat) {
        warnings.add(
          'Consider selecting accessibility-friendly seats '
          'for passengers with special needs',
        );
      }
    }

    // 5) If it’s a group (more than one), ensure they are grouped
    if (totalPassengers > 1) {
      final isGrouped = _areSeatsGrouped(selectedSeatIds);
      if (!isGrouped) {
        warnings.add(
          'Selected seats are not grouped together – '
          'consider choosing adjacent seats',
        );
      }
    }

    return SeatSelectionValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // ─── Helper: Detect “accessibility” seat by some rule:
  // e.g. “A” or “F” columns or specific rows (“20”, “21” etc.)
  static bool _isAccessibilitySeat(String seatId) {
    // Any seat ending in A or F is treated as “accessible,” or rows 20/21:
    return seatId.endsWith('A') ||
        seatId.endsWith('F') ||
        seatId.startsWith('20') ||
        seatId.startsWith('21');
  }

  // ─── Helper: Are these seat IDs grouped (same row or adjacent rows)?
  static bool _areSeatsGrouped(List<String> seatIds) {
    if (seatIds.length <= 1) return true;

    // 1) Group by row number
    final rowGroups = <int, List<String>>{};
    for (final seatId in seatIds) {
      final row = int.tryParse(seatId.replaceAll(RegExp(r'[A-Z]'), '')) ?? 0;
      rowGroups.putIfAbsent(row, () => []).add(seatId);
    }

    // 2) Sort the row keys
    final rows = rowGroups.keys.toList()..sort();

    if (rows.length == 1) {
      // All seats in the same row – check they are consecutive
      final sameRowSeats = rowGroups[rows.first]!..sort();
      return _areConsecutive(sameRowSeats);
    }

    if (rows.length == 2) {
      // Two different rows – check they are adjacent (difference ≤ 1)
      return (rows[1] - rows[0]) <= 1;
    }

    // More than two rows = not considered “grouped”
    return false;
  }

  // ─── Helper: Are a list of seat IDs consecutive in the same row?
  // (e.g. “12A”, “12B”, “12C” are consecutive; but “12C”→“12D” is allowed gap over aisle)
  static bool _areConsecutive(List<String> seats) {
    if (seats.length <= 1) return true;

    // Extract just the column letters for each seat in this row
    final columns =
        seats.map((s) => s.replaceAll(RegExp(r'[0-9]'), '')).toList();
    final columnOrder = <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'J',
      'K'
    ];

    for (int i = 1; i < columns.length; i++) {
      final cur = columns[i];
      final prev = columns[i - 1];
      final idxCur = columnOrder.indexOf(cur);
      final idxPrev = columnOrder.indexOf(prev);

      // If either letter isn’t in our known list, fail
      if (idxCur == -1 || idxPrev == -1) return false;

      // If exactly next in the array → consecutive (e.g. B after A)
      if (idxCur == idxPrev + 1) continue;

      // Otherwise, check if it’s an allowed aisle gap (e.g. C–D or F–G)
      if (!_isAllowedGap(prev, cur)) {
        return false;
      }
    }
    return true;
  }

  static bool _isAllowedGap(String col1, String col2) {
    // Common aisle gaps: C–D, F–G, etc.
    final aisleGaps = [
      ['C', 'D'],
      ['F', 'G'],
    ];
    return aisleGaps.any((gap) =>
        (gap[0] == col1 && gap[1] == col2) ||
        (gap[1] == col1 && gap[0] == col2));
  }
}
