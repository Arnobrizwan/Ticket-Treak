import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  // Shared color palette
  static const Color backgroundColor = Color(0xFFF5F0E1);
  static const Color primaryColor = Color(0xFF5C2E00);
  static const Color secondaryColor = Color(0xFF8B5000);
  static const Color textColor = Color(0xFF35281E);
  static const Color darkGrey = Color(0xFF7E5E3C);
  static const Color accentColor = Color(0xFFD4A373);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color cardBackgroundColor = Color(0xFFFFFDF7);

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _mapDbStatusToUiStatus(String? dbStatus, DateTime? departureDate) {
    if (dbStatus?.toLowerCase() == 'cancelled') return 'cancelled';
    if (departureDate != null && departureDate.isBefore(DateTime.now()))
      return 'completed';
    if (dbStatus?.toLowerCase() == 'completed') return 'completed';
    return 'upcoming';
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    User? user = _auth.currentUser;
    if (user == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Please log in.')));
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('departureDate', descending: true)
          .get();
      setState(() {
        _bookings = snapshot.docs.map((doc) {
          final data = doc.data();
          final departureDate = (data['departureDate'] as Timestamp?)?.toDate();
          final origin = data['originCode'] ?? '?';
          final dest = data['destinationCode'] ?? '?';
          return {
            'id': doc.id,
            'bookingReference': data['bookingReference'] ?? 'N/A',
            'flight': '$origin > $dest',
            'origin': origin,
            'destination': dest,
            'date': departureDate != null
                ? DateFormat('E, dd MMM yy').format(departureDate)
                : 'N/A',
            'time': departureDate != null
                ? DateFormat('h:mm a').format(departureDate)
                : 'N/A',
            'total': (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
            'status': _mapDbStatusToUiStatus(
                data['status'] as String?, departureDate),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching bookings: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCancellationDetailsDialog(
      Map<String, dynamic> booking) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      final doc =
          await _firestore.collection('bookings').doc(booking['id']).get();
      if (!doc.exists) throw Exception("Booking not found");

      final passengers =
          List<Map<String, dynamic>>.from(doc.data()?['passengers'] ?? []);

      // ignore: use_build_context_synchronously
      Navigator.pop(context);

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Cancellation"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("You are about to cancel the following booking:"),
                const SizedBox(height: 16),
                _buildInfoRow(
                    Icons.flight_takeoff_rounded, "Flight", booking['flight']),
                _buildInfoRow(Icons.calendar_today, "Date", booking['date']),
                const Divider(height: 24),
                const Text("Passengers:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                if (passengers.isNotEmpty)
                  ...passengers
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                                "• ${p['fullName'] ?? 'Unknown Passenger'}"),
                          ))
                      .toList()
                else
                  const Text("No passenger details found."),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Refund:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: textColor)),
                    Text(
                      "MYR ${booking['total'].toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: successColor,
                          fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                    "Are you sure you want to proceed? This action cannot be undone."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO, KEEP BOOKING"),
            ),
            // THIS IS THE FIX
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    errorColor, // Explicitly set the red background
                foregroundColor: Colors.white, // Ensure the text is white
              ),
              onPressed: () {
                Navigator.pop(context);
                _cancelBooking(booking['id'], booking['total']);
              },
              child: const Text("YES, CANCEL"),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading details: $e")));
    }
  }

  Future<void> _cancelBooking(String bookingId, double refundAmount) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'refundStatus': 'Pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(
                'Booking cancelled. Refund of MYR ${refundAmount.toStringAsFixed(2)} will be processed.'),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))));
      }
      await _fetchBookings();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling booking: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text('My Bookings',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                style: const TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search by route or Booking Ref…',
                  hintStyle: const TextStyle(color: darkGrey),
                  prefixIcon: const Icon(Icons.search, color: darkGrey),
                  filled: true,
                  fillColor: accentColor.withOpacity(0.2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onChanged: (q) =>
                    setState(() => _searchQuery = q.trim().toLowerCase()),
              ),
            ),
            TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: darkGrey,
                indicatorColor: primaryColor,
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled')
                ]),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : TabBarView(controller: _tabController, children: [
                      _buildBookingList('upcoming'),
                      _buildBookingList('completed'),
                      _buildBookingList('cancelled')
                    ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(String status) {
    final filteredBookings = _bookings.where((booking) {
      final searchLower = _searchQuery.toLowerCase();
      return booking['status'] == status &&
          (booking['flight'].toLowerCase().contains(searchLower) ||
              booking['bookingReference'].toLowerCase().contains(searchLower));
    }).toList();

    if (filteredBookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchBookings,
        child: ListView(children: const [
          SizedBox(height: 100),
          Center(
              child: Text('No bookings found.',
                  style: TextStyle(fontSize: 16, color: darkGrey)))
        ]),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          final statusColor = booking['status'] == 'upcoming'
              ? successColor
              : (booking['status'] == 'cancelled'
                  ? errorColor
                  : secondaryColor);

          return Card(
            elevation: 4,
            shadowColor: primaryColor.withOpacity(0.2),
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.bookingDetail,
                  arguments: booking['id']),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: cardBackgroundColor,
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff_rounded,
                            color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("ROUTE",
                                  style: TextStyle(
                                      color: darkGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(booking['origin'],
                                      style: const TextStyle(
                                          color: textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Icon(Icons.arrow_right_alt_rounded,
                                        color: darkGrey),
                                  ),
                                  Text(booking['destination'],
                                      style: const TextStyle(
                                          color: textColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              )
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(booking['status'].toString().capitalize(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          backgroundColor: statusColor,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: backgroundColor),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.calendar_today_outlined, "Date",
                            booking['date']),
                        _buildInfoRow(Icons.access_time_outlined, "Time",
                            booking['time']),
                        _buildInfoRow(Icons.confirmation_number_outlined,
                            "Booking Ref", booking['bookingReference']),
                      ],
                    ),
                  ),
                  if (booking['status'] == 'upcoming')
                    Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: backgroundColor),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: TextButton.icon(
                              onPressed: () =>
                                  _showCancellationDetailsDialog(booking),
                              icon: const Icon(Icons.cancel_outlined, size: 20),
                              label: const Text("Cancel Booking"),
                              style: TextButton.styleFrom(
                                  foregroundColor: errorColor,
                                  minimumSize: const Size(double.infinity, 36)),
                            ),
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: darkGrey, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: darkGrey, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
