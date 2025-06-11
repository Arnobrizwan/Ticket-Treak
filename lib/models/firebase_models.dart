import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ticket_trek/models/seat_model.dart';
import 'package:ticket_trek/models/addon_model.dart';

// Main booking model
class FlightBooking {
  final String id;
  final String userId;
  final String bookingReference;
  final Map<String, dynamic> flightOffer;
  final String originCode;
  final String destinationCode;
  final DateTime departureDate;
  final int passengerCount;
  final String travelClass;
  final bool isStudentFare;
  final double flightPrice;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SeatBooking? seatBooking;
  final AddonBooking? addonBooking;
  final double totalAmount;
  final PaymentInfo? paymentInfo;

  const FlightBooking({
    required this.id,
    required this.userId,
    required this.bookingReference,
    required this.flightOffer,
    required this.originCode,
    required this.destinationCode,
    required this.departureDate,
    required this.passengerCount,
    required this.travelClass,
    required this.isStudentFare,
    required this.flightPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.seatBooking,
    this.addonBooking,
    required this.totalAmount,
    this.paymentInfo,
  });

  factory FlightBooking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlightBooking(
      id: doc.id,
      userId: data['userId'] as String,
      bookingReference: data['bookingReference'] as String,
      flightOffer: Map<String, dynamic>.from(data['flightOffer'] as Map),
      originCode: data['originCode'] as String,
      destinationCode: data['destinationCode'] as String,
      departureDate: (data['departureDate'] as Timestamp).toDate(),
      passengerCount: data['passengerCount'] as int,
      travelClass: data['travelClass'] as String,
      isStudentFare: data['isStudentFare'] as bool? ?? false,
      flightPrice: (data['flightPrice'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      seatBooking: data['seatBooking'] != null
          ? SeatBooking.fromMap(Map<String, dynamic>.from(data['seatBooking'] as Map))
          : null,
      addonBooking: data['addonBooking'] != null
          ? AddonBooking.fromMap(Map<String, dynamic>.from(data['addonBooking'] as Map))
          : null,
      totalAmount: (data['totalAmount'] as num).toDouble(),
      paymentInfo: data['paymentInfo'] != null
          ? PaymentInfo.fromMap(Map<String, dynamic>.from(data['paymentInfo'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'bookingReference': bookingReference,
      'flightOffer': flightOffer,
      'originCode': originCode,
      'destinationCode': destinationCode,
      'departureDate': Timestamp.fromDate(departureDate),
      'passengerCount': passengerCount,
      'travelClass': travelClass,
      'isStudentFare': isStudentFare,
      'flightPrice': flightPrice,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'seatBooking': seatBooking?.toMap(),
      'addonBooking': addonBooking?.toMap(),
      'totalAmount': totalAmount,
      'paymentInfo': paymentInfo?.toMap(),
    };
  }

  FlightBooking copyWith({
    String? id,
    String? userId,
    String? bookingReference,
    Map<String, dynamic>? flightOffer,
    String? originCode,
    String? destinationCode,
    DateTime? departureDate,
    int? passengerCount,
    String? travelClass,
    bool? isStudentFare,
    double? flightPrice,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    SeatBooking? seatBooking,
    AddonBooking? addonBooking,
    double? totalAmount,
    PaymentInfo? paymentInfo,
  }) {
    return FlightBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingReference: bookingReference ?? this.bookingReference,
      flightOffer: flightOffer ?? this.flightOffer,
      originCode: originCode ?? this.originCode,
      destinationCode: destinationCode ?? this.destinationCode,
      departureDate: departureDate ?? this.departureDate,
      passengerCount: passengerCount ?? this.passengerCount,
      travelClass: travelClass ?? this.travelClass,
      isStudentFare: isStudentFare ?? this.isStudentFare,
      flightPrice: flightPrice ?? this.flightPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seatBooking: seatBooking ?? this.seatBooking,
      addonBooking: addonBooking ?? this.addonBooking,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }
}

// Seat booking model
class SeatBooking {
  final Map<String, String> seatAssignments; // PassengerIndex -> SeatId
  final Map<String, SeatDetails> seatDetails; // SeatId -> SeatDetails
  final double totalSeatCost;
  final DateTime selectedAt;
  final String aircraftType;
  final String flightNumber;

  const SeatBooking({
    required this.seatAssignments,
    required this.seatDetails,
    required this.totalSeatCost,
    required this.selectedAt,
    required this.aircraftType,
    required this.flightNumber,
  });

  factory SeatBooking.fromMap(Map<String, dynamic> data) {
    return SeatBooking(
      seatAssignments: Map<String, String>.from(data['seatAssignments'] as Map),
      seatDetails: (data['seatDetails'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, SeatDetails.fromMap(Map<String, dynamic>.from(value as Map))),
      ),
      totalSeatCost: (data['totalSeatCost'] as num).toDouble(),
      selectedAt: (data['selectedAt'] as Timestamp).toDate(),
      aircraftType: data['aircraftType'] as String,
      flightNumber: data['flightNumber'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seatAssignments': seatAssignments,
      'seatDetails': seatDetails.map((key, value) => MapEntry(key, value.toMap())),
      'totalSeatCost': totalSeatCost,
      'selectedAt': Timestamp.fromDate(selectedAt),
      'aircraftType': aircraftType,
      'flightNumber': flightNumber,
    };
  }
}

// **Seat details model (no more `position`)**
class SeatDetails {
  final String seatId;
  final int row;
  final String column;
  final SeatCategory category;
  final bool isEmergencyExit;
  final bool hasAccessibility;
  final String deck;
  final double price;

  const SeatDetails({
    required this.seatId,
    required this.row,
    required this.column,
    required this.category,
    required this.isEmergencyExit,
    required this.hasAccessibility,
    required this.deck,
    required this.price,
  });

  factory SeatDetails.fromSeat(Seat seat, double price) {
    return SeatDetails(
      seatId: seat.id,
      row: seat.row,
      column: seat.column,
      category: seat.category,
      isEmergencyExit: seat.isEmergencyExit,
      hasAccessibility: seat.hasAccessibility,
      deck: seat.deck,
      price: price,
    );
  }

  factory SeatDetails.fromMap(Map<String, dynamic> data) {
    return SeatDetails(
      seatId: data['seatId'] as String,
      row: data['row'] as int,
      column: data['column'] as String,
      category: SeatCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => SeatCategory.economy,
      ),
      isEmergencyExit: data['isEmergencyExit'] as bool? ?? false,
      hasAccessibility: data['hasAccessibility'] as bool? ?? false,
      deck: data['deck'] as String? ?? 'Main',
      price: (data['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seatId': seatId,
      'row': row,
      'column': column,
      'category': category.name,
      'isEmergencyExit': isEmergencyExit,
      'hasAccessibility': hasAccessibility,
      'deck': deck,
      'price': price,
    };
  }
}

// Add-on booking model
class AddonBooking {
  final List<BookedAddon> selectedAddons;
  final double totalAddonCost;
  final DateTime selectedAt;
  final Map<String, dynamic> validationResult;

  const AddonBooking({
    required this.selectedAddons,
    required this.totalAddonCost,
    required this.selectedAt,
    required this.validationResult,
  });

  factory AddonBooking.fromMap(Map<String, dynamic> data) {
    return AddonBooking(
      selectedAddons: (data['selectedAddons'] as List<dynamic>)
          .map((item) => BookedAddon.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      totalAddonCost: (data['totalAddonCost'] as num).toDouble(),
      selectedAt: (data['selectedAt'] as Timestamp).toDate(),
      validationResult: Map<String, dynamic>.from(data['validationResult'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedAddons': selectedAddons.map((addon) => addon.toMap()).toList(),
      'totalAddonCost': totalAddonCost,
      'selectedAt': Timestamp.fromDate(selectedAt),
      'validationResult': validationResult,
    };
  }
}

// Booked add-on model
class BookedAddon {
  final String id;
  final AddonType type;
  final String displayName;
  final String description;
  final double price;
  final String currency;
  final List<String> features;
  final AddonCategory category;
  final bool isPopular;
  final bool isRecommended;
  final Map<String, dynamic> metadata;

  const BookedAddon({
    required this.id,
    required this.type,
    required this.displayName,
    required this.description,
    required this.price,
    required this.currency,
    required this.features,
    required this.category,
    required this.isPopular,
    required this.isRecommended,
    required this.metadata,
  });

  factory BookedAddon.fromFlightAddon(FlightAddon addon) {
    return BookedAddon(
      id: addon.id,
      type: addon.type,
      displayName: addon.type.displayName,
      description: addon.type.description,
      price: addon.price,
      currency: addon.currency,
      features: addon.features,
      category: addon.type.category,
      isPopular: addon.isPopular,
      isRecommended: addon.isRecommended,
      metadata: addon.metadata,
    );
  }

  factory BookedAddon.fromMap(Map<String, dynamic> data) {
    return BookedAddon(
      id: data['id'] as String,
      type: AddonType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AddonType.extraLuggage20kg,
      ),
      displayName: data['displayName'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      currency: data['currency'] as String,
      features: List<String>.from(data['features'] as List),
      category: AddonCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => AddonCategory.baggage,
      ),
      isPopular: data['isPopular'] as bool? ?? false,
      isRecommended: data['isRecommended'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'description': description,
      'price': price,
      'currency': currency,
      'features': features,
      'category': category.name,
      'isPopular': isPopular,
      'isRecommended': isRecommended,
      'metadata': metadata,
    };
  }
}

// Payment info model
class PaymentInfo {
  final String paymentMethod;
  final String transactionId;
  final DateTime paidAt;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final Map<String, dynamic> gatewayResponse;

  const PaymentInfo({
    required this.paymentMethod,
    required this.transactionId,
    required this.paidAt,
    required this.amount,
    required this.currency,
    required this.status,
    required this.gatewayResponse,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> data) {
    return PaymentInfo(
      paymentMethod: data['paymentMethod'] as String,
      transactionId: data['transactionId'] as String,
      paidAt: (data['paidAt'] as Timestamp).toDate(),
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      gatewayResponse: Map<String, dynamic>.from(data['gatewayResponse'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'paidAt': Timestamp.fromDate(paidAt),
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'gatewayResponse': gatewayResponse,
    };
  }
}

// Enums
enum BookingStatus {
  pending,
  seatSelected,
  addonsSelected,
  confirmed,
  paid,
  cancelled,
  completed,
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.seatSelected:
        return 'Seat Selected';
      case BookingStatus.addonsSelected:
        return 'Add-ons Selected';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.paid:
        return 'Paid';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
    }
  }

  bool get canModify {
    return this == BookingStatus.pending ||
           this == BookingStatus.seatSelected ||
           this == BookingStatus.addonsSelected;
  }
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
}

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}