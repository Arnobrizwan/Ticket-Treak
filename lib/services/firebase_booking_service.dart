import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticket_trek/models/firebase_models.dart';
import 'package:ticket_trek/models/seat_model.dart';
import 'package:ticket_trek/models/addon_model.dart';

class FirebaseBookingService {
  static final FirebaseBookingService _instance = FirebaseBookingService._internal();
  factory FirebaseBookingService() => _instance;
  FirebaseBookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _bookingsCollection => _firestore.collection('bookings');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Creates a new flight booking
  Future<FlightBooking> createFlightBooking({
    required Map<String, dynamic> flightOffer,
    required String originCode,
    required String destinationCode,
    required DateTime departureDate,
    required int passengerCount,
    required String travelClass,
    required bool isStudentFare,
    required double flightPrice,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final bookingReference = _generateBookingReference();
      final now = DateTime.now();

      final booking = FlightBooking(
        id: '', // Will be set by Firestore
        userId: user.uid,
        bookingReference: bookingReference,
        flightOffer: flightOffer,
        originCode: originCode,
        destinationCode: destinationCode,
        departureDate: departureDate,
        passengerCount: passengerCount,
        travelClass: travelClass,
        isStudentFare: isStudentFare,
        flightPrice: flightPrice,
        status: BookingStatus.pending,
        createdAt: now,
        updatedAt: now,
        totalAmount: flightPrice,
      );

      final docRef = await _bookingsCollection.add(booking.toFirestore());
      
      // Update user's booking history
      await _updateUserBookingHistory(user.uid, docRef.id);

      return booking.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Updates booking with seat selection
  Future<FlightBooking> updateWithSeatSelection({
    required String bookingId,
    required Map<String, String> seatAssignments,
    required List<Seat> allSeats,
    required Map<SeatCategory, double> seatPricing,
    required String aircraftType,
    required String flightNumber,
  }) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }

      // Create seat details map
      final seatDetails = <String, SeatDetails>{};
      double totalSeatCost = 0.0;

      for (final entry in seatAssignments.entries) {
        final seatId = entry.value;
        final seat = allSeats.firstWhere((s) => s.id == seatId);
        final price = seatPricing[seat.category] ?? 0.0;
        
        seatDetails[seatId] = SeatDetails.fromSeat(seat, price);
        totalSeatCost += price;
      }

      final seatBooking = SeatBooking(
        seatAssignments: seatAssignments,
        seatDetails: seatDetails,
        totalSeatCost: totalSeatCost,
        selectedAt: DateTime.now(),
        aircraftType: aircraftType,
        flightNumber: flightNumber,
      );

      final updatedBooking = booking.copyWith(
        seatBooking: seatBooking,
        status: BookingStatus.seatSelected,
        totalAmount: booking.flightPrice + totalSeatCost + (booking.addonBooking?.totalAddonCost ?? 0.0),
        updatedAt: DateTime.now(),
      );

      await _bookingsCollection.doc(bookingId).update(updatedBooking.toFirestore());

      // Log seat selection activity
      await _logBookingActivity(
        bookingId: bookingId,
        activity: 'Seat Selection',
        details: {
          'selectedSeats': seatAssignments,
          'totalCost': totalSeatCost,
          'aircraftType': aircraftType,
        },
      );

      return updatedBooking;
    } catch (e) {
      throw Exception('Failed to update booking with seat selection: $e');
    }
  }

  /// Updates booking with add-on selection
  Future<FlightBooking> updateWithAddonSelection({
    required String bookingId,
    required AddonSelection addonSelection,
    required Map<String, dynamic> validationResult,
  }) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }

      final bookedAddons = addonSelection.addons
          .map((addon) => BookedAddon.fromFlightAddon(addon))
          .toList();

      final addonBooking = AddonBooking(
        selectedAddons: bookedAddons,
        totalAddonCost: addonSelection.totalPrice,
        selectedAt: DateTime.now(),
        validationResult: validationResult,
      );

      final updatedBooking = booking.copyWith(
        addonBooking: addonBooking,
        status: BookingStatus.addonsSelected,
        totalAmount: booking.flightPrice + (booking.seatBooking?.totalSeatCost ?? 0.0) + addonSelection.totalPrice,
        updatedAt: DateTime.now(),
      );

      await _bookingsCollection.doc(bookingId).update(updatedBooking.toFirestore());

      // Log add-on selection activity
      await _logBookingActivity(
        bookingId: bookingId,
        activity: 'Add-on Selection',
        details: {
          'selectedAddons': bookedAddons.map((a) => a.displayName).toList(),
          'totalCost': addonSelection.totalPrice,
          'count': bookedAddons.length,
        },
      );

      return updatedBooking;
    } catch (e) {
      throw Exception('Failed to update booking with add-on selection: $e');
    }
  }

  /// Confirms the booking
  Future<FlightBooking> confirmBooking({
    required String bookingId,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }

      final updatedBooking = booking.copyWith(
        paymentInfo: paymentInfo,
        status: paymentInfo.status == PaymentStatus.completed 
            ? BookingStatus.paid 
            : BookingStatus.confirmed,
        updatedAt: DateTime.now(),
      );

      await _bookingsCollection.doc(bookingId).update(updatedBooking.toFirestore());

      // Log booking confirmation
      await _logBookingActivity(
        bookingId: bookingId,
        activity: 'Booking Confirmed',
        details: {
          'paymentMethod': paymentInfo.paymentMethod,
          'transactionId': paymentInfo.transactionId,
          'amount': paymentInfo.amount,
          'status': paymentInfo.status.name,
        },
      );

      // Send confirmation email (implement as needed)
      await _sendBookingConfirmationEmail(updatedBooking);

      return updatedBooking;
    } catch (e) {
      throw Exception('Failed to confirm booking: $e');
    }
  }

  /// Gets user's bookings
  Future<List<FlightBooking>> getUserBookings({
    int limit = 20,
    BookingStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      Query query = _bookingsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (fromDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }

      if (toDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      final snapshot = await query.limit(limit).get();
      
      return snapshot.docs
          .map((doc) => FlightBooking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Gets a specific booking by ID
  Future<FlightBooking?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) {
        return null;
      }

      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }

      return booking;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Gets booking by reference number
  Future<FlightBooking?> getBookingByReference(String bookingReference) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _bookingsCollection
          .where('userId', isEqualTo: user.uid)
          .where('bookingReference', isEqualTo: bookingReference)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return FlightBooking.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get booking by reference: $e');
    }
  }

  /// Cancels a booking
  Future<FlightBooking> cancelBooking(String bookingId, String reason) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (!doc.exists) {
        throw Exception('Booking not found');
      }

      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }

      // Check if booking can be cancelled
      if (!booking.status.canModify) {
        throw Exception('Booking cannot be cancelled in current status');
      }

      final updatedBooking = booking.copyWith(
        status: BookingStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await _bookingsCollection.doc(bookingId).update(updatedBooking.toFirestore());

      // Log cancellation
      await _logBookingActivity(
        bookingId: bookingId,
        activity: 'Booking Cancelled',
        details: {
          'reason': reason,
          'previousStatus': booking.status.name,
        },
      );

      return updatedBooking;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Gets booking statistics for user
  Future<Map<String, dynamic>> getUserBookingStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await _bookingsCollection
          .where('userId', isEqualTo: user.uid)
          .get();

      final bookings = snapshot.docs
          .map((doc) => FlightBooking.fromFirestore(doc))
          .toList();

      final stats = {
        'totalBookings': bookings.length,
        'completedBookings': bookings.where((b) => b.status == BookingStatus.completed).length,
        'cancelledBookings': bookings.where((b) => b.status == BookingStatus.cancelled).length,
        'totalSpent': bookings
            .where((b) => b.status == BookingStatus.paid || b.status == BookingStatus.completed)
            .fold<double>(0.0, (sum, booking) => sum + booking.totalAmount),
        'upcomingTrips': bookings
            .where((b) => 
                b.departureDate.isAfter(DateTime.now()) && 
                (b.status == BookingStatus.paid || b.status == BookingStatus.confirmed))
            .length,
        'pastTrips': bookings
            .where((b) => 
                b.departureDate.isBefore(DateTime.now()) && 
                b.status == BookingStatus.completed)
            .length,
      };

      return stats;
    } catch (e) {
      throw Exception('Failed to get booking statistics: $e');
    }
  }

  /// Private helper methods

  String _generateBookingReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    
    String result = 'TT'; // Ticket Trek prefix
    for (int i = 0; i < 4; i++) {
      result += chars[random.nextInt(chars.length)];
    }
    result += timestamp;
    
    return result;
  }

  Future<void> _updateUserBookingHistory(String userId, String bookingId) async {
    try {
      await _usersCollection.doc(userId).set({
        'bookingHistory': FieldValue.arrayUnion([bookingId]),
        'lastBookingAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't fail the booking creation
      print('Failed to update user booking history: $e');
    }
  }

  Future<void> _logBookingActivity({
    required String bookingId,
    required String activity,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _firestore
          .collection('booking_activities')
          .add({
        'bookingId': bookingId,
        'activity': activity,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Failed to log booking activity: $e');
    }
  }

  Future<void> _sendBookingConfirmationEmail(FlightBooking booking) async {
    try {
      // Implementation depends on your email service
      // This could trigger a Cloud Function or call an email API
      
      await _firestore
          .collection('email_queue')
          .add({
        'to': _auth.currentUser?.email,
        'template': 'booking_confirmation',
        'data': {
          'bookingReference': booking.bookingReference,
          'passengerName': _auth.currentUser?.displayName ?? 'Passenger',
          'flightDetails': {
            'route': '${booking.originCode} → ${booking.destinationCode}',
            'date': booking.departureDate.toIso8601String(),
            'class': booking.travelClass,
          },
          'totalAmount': booking.totalAmount,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the booking
      print('Failed to queue confirmation email: $e');
    }
  }

  /// Stream methods for real-time updates

  /// Stream user's bookings
  Stream<List<FlightBooking>> streamUserBookings() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    return _bookingsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlightBooking.fromFirestore(doc))
            .toList());
  }

  /// Stream a specific booking
  Stream<FlightBooking?> streamBooking(String bookingId) {
    return _bookingsCollection
        .doc(bookingId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      
      final booking = FlightBooking.fromFirestore(doc);
      
      // Verify user owns this booking
      final user = _auth.currentUser;
      if (user == null || booking.userId != user.uid) {
        throw Exception('Unauthorized access to booking');
      }
      
      return booking;
    });
  }
}