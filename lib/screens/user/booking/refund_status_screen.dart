import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../routes/app_routes.dart';

class RefundStatusScreen extends StatefulWidget {
  final String bookingId;

  const RefundStatusScreen({super.key, required this.bookingId});

  @override
  State<RefundStatusScreen> createState() => _RefundStatusScreenState();
}

class _RefundStatusScreenState extends State<RefundStatusScreen> {
  // Color palette from HomeDashboard
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color pendingColor = Color(0xFFFF9800);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _bookingNumber = '';
  String _passengerName = '';
  double _refundAmount = 0.0;
  String _submissionDate = '';
  String _currentStatus = 'Requested';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  // Fetch initial data from Firestore
  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await _firestore
            .collection('bookings')
            .doc(widget.bookingId)
            .get();

        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          var passenger = data['passengers'][0] ?? {};
          Timestamp? timestamp = data['updatedAt'] ?? data['timestamp'];
          String formattedDate = timestamp != null
              ? DateFormat('d MMMM yyyy, h:mm a').format(timestamp.toDate())
              : 'Unknown Date';

          setState(() {
            _bookingNumber = data['bookingNumber'] ?? widget.bookingId;
            _passengerName = passenger['fullName'] ?? 'Arnob Rizwan';
            _refundAmount = data['fareSummary']['total']?.toDouble() - 2.0 ?? 0.0; // Subtract cancellation fee
            _submissionDate = formattedDate;
            _currentStatus = data['refundStatus'] ?? 'Requested';
            _isLoading = false;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Booking not found.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching data: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Contact Support (mocked)
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting support...'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: _firestore
                      .collection('bookings')
                      .doc(widget.bookingId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading status.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      );
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    _currentStatus = data['refundStatus'] ?? 'Requested';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: primaryColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Refund Status',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
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
                                'Refund Request Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow('Booking Number', _bookingNumber),
                              _buildSummaryRow('Passenger Name', _passengerName),
                              _buildSummaryRow(
                                'Refund Amount',
                                '\$${_refundAmount.toStringAsFixed(2)} USD',
                              ),
                              _buildSummaryRow('Submission Date', _submissionDate),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
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
                                'Processing Timeline',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTimelineStep(
                                'Refund Requested',
                                _submissionDate,
                                _currentStatus == 'Requested' ||
                                    _currentStatus == 'Under Review' ||
                                    _currentStatus == 'Processed',
                                true,
                              ),
                              _buildTimelineStep(
                                'Refund Under Review',
                                _currentStatus == 'Under Review' ||
                                        _currentStatus == 'Processed'
                                    ? DateFormat('d MMMM yyyy, h:mm a')
                                        .format(DateTime.now())
                                    : '',
                                _currentStatus == 'Under Review' ||
                                    _currentStatus == 'Processed',
                                false,
                              ),
                              _buildTimelineStep(
                                'Refund Processed',
                                _currentStatus == 'Processed'
                                    ? DateFormat('d MMMM yyyy, h:mm a')
                                        .format(DateTime.now())
                                    : '',
                                _currentStatus == 'Processed',
                                false,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _contactSupport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Contact Support'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: darkGrey),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, String date, bool isActive, bool isFirst) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? (isFirst ? successColor : pendingColor) : subtleGrey,
              border: Border.all(
                color: isActive ? (isFirst ? successColor : pendingColor) : darkGrey,
                width: 2,
              ),
            ),
            child: isFirst
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? textColor : darkGrey,
                  ),
                ),
                if (date.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: darkGrey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}