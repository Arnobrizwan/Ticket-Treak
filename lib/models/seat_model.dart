// lib/models/seat_model.dart

enum SeatStatus {
  available,
  occupied,
  selected,
}

enum SeatCategory {
  economy,
  premiumEconomy,
  business,
  first,
  emergencyExit,
}

extension SeatCategoryExtension on SeatCategory {
  String get displayName {
    switch (this) {
      case SeatCategory.economy:
        return 'Economy';
      case SeatCategory.premiumEconomy:
        return 'Premium Economy';
      case SeatCategory.business:
        return 'Business';
      case SeatCategory.first:
        return 'First Class';
      case SeatCategory.emergencyExit:
        return 'Emergency Exit';
    }
  }
}

class Seat {
  final String id;
  final int row;
  final String column;
  final SeatStatus status;
  final SeatCategory category;
  final bool hasAccessibility;
  final bool isEmergencyExit;
  final String deck;

  const Seat({
    required this.id,
    required this.row,
    required this.column,
    required this.status,
    required this.category,
    this.hasAccessibility = false,
    this.isEmergencyExit = false,
    this.deck = 'Main',
  });

  factory Seat.fromJson(Map<String, dynamic> json) {
    return Seat(
      id: json['id'] as String,
      row: json['row'] as int,
      column: json['column'] as String,
      status: SeatStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SeatStatus.available,
      ),
      category: SeatCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SeatCategory.economy,
      ),
      hasAccessibility: json['hasAccessibility'] as bool? ?? false,
      isEmergencyExit: json['isEmergencyExit'] as bool? ?? false,
      deck: json['deck'] as String? ?? 'Main',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'row': row,
      'column': column,
      'status': status.name,
      'category': category.name,
      'hasAccessibility': hasAccessibility,
      'isEmergencyExit': isEmergencyExit,
      'deck': deck,
    };
  }

  Seat copyWith({
    String? id,
    int? row,
    String? column,
    SeatStatus? status,
    SeatCategory? category,
    bool? hasAccessibility,
    bool? isEmergencyExit,
    String? deck,
  }) {
    return Seat(
      id: id ?? this.id,
      row: row ?? this.row,
      column: column ?? this.column,
      status: status ?? this.status,
      category: category ?? this.category,
      hasAccessibility: hasAccessibility ?? this.hasAccessibility,
      isEmergencyExit: isEmergencyExit ?? this.isEmergencyExit,
      deck: deck ?? this.deck,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Seat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}