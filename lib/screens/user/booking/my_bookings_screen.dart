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

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  // Color palette from HomeDashboard
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;

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

  // Fetch bookings from Firestore
  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .get();

        setState(() {
          _bookings = snapshot.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            Timestamp? timestamp = data['timestamp'];
            String formattedDate = timestamp != null
                ? DateFormat('d MMMM yyyy, h:mm a (O)').format(timestamp.toDate())
                : 'Unknown Date';

            return {
              'id': doc.id,
              'flight': '${data['flight']['code']} | ${data['flight']['route']}',
              'date': formattedDate,
              'status': data['status'] ?? 'Unknown',
              'total': data['fareSummary']['total']?.toDouble() ?? 0.0,
            };
          }).toList();
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching bookings: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to view bookings.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cancel a booking
  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _fetchBookings(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking cancelled successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // View booking details
  void _viewDetails(String bookingId) {
    Navigator.pushNamed(context, AppRoutes.bookingConfirmation, arguments: bookingId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'My Bookings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
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
                Tab(text: 'Cancelled'),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBookingList('Upcoming'),
                        _buildBookingList('Completed'),
                        _buildBookingList('Cancelled'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(String status) {
    final filteredBookings = _bookings.where((booking) => booking['status'] == status.toLowerCase()).toList();

    if (filteredBookings.isEmpty) {
      return const Center(
        child: Text(
          'No bookings found.',
          style: TextStyle(fontSize: 16, color: darkGrey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: subtleGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.flight, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      booking['flight'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  booking['date'],
                  style: TextStyle(fontSize: 14, color: darkGrey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking['status'].toString().capitalize(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: booking['status'] == 'upcoming'
                            ? Colors.green
                            : booking['status'] == 'completed'
                                ? Colors.grey
                                : Colors.red,
                      ),
                    ),
                    Text(
                      '\$${booking['total'].toStringAsFixed(2)} USD',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => _viewDetails(booking['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('View Details'),
                    ),
                    if (booking['status'] == 'upcoming')
                      ElevatedButton(
                        onPressed: () => _cancelBooking(booking['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Cancel Booking'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Extension to capitalize the first letter
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}