import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _filterCategory = 'All';

  Future<Map<String, int>> _fetchAnalyticsData() async {
    final snapshot = await _firestore
        .collectionGroup('flights')
        .where('departureTime', isGreaterThanOrEqualTo: _startDate.toIso8601String())
        .where('departureTime', isLessThanOrEqualTo: _endDate.toIso8601String())
        .get();
    final flightCount = snapshot.docs.length;

    final bookingSnapshot = await _firestore
        .collectionGroup('bookings')
        .where('createdAt', isGreaterThanOrEqualTo: _startDate)
        .where('createdAt', isLessThanOrEqualTo: _endDate)
        .get();
    final bookingCount = bookingSnapshot.docs.length;

    final refundSnapshot = await _firestore
        .collectionGroup('refund_requests')
        .where('createdAt', isGreaterThanOrEqualTo: _startDate)
        .where('createdAt', isLessThanOrEqualTo: _endDate)
        .get();
    final refundCount = refundSnapshot.docs.length;

    final userSnapshot = await _firestore
        .collectionGroup('users')
        .where('isActive', isEqualTo: true)
        .get();
    final activeUserCount = userSnapshot.docs.length;

    return {
      'flightCount': flightCount,
      'bookingCount': bookingCount,
      'refundCount': refundCount,
      'activeUserCount': activeUserCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
        ),
        title: const Text('Admin Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Start Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(
                        text: '${_startDate.toLocal().toString().split(' ')[0]}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'End Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    controller: TextEditingController(
                        text: '${_endDate.toLocal().toString().split(' ')[0]}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _endDate = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, int>>(
                future: _fetchAnalyticsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('No data available'));
                  }
                  final data = snapshot.data!;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildKpiCard('Total Flights', data['flightCount']?.toString() ?? '0'),
                          _buildKpiCard('Total Bookings', data['bookingCount']?.toString() ?? '0'),
                          _buildKpiCard('Refund Requests', data['refundCount']?.toString() ?? '0'),
                          _buildKpiCard('Active Users', data['activeUserCount']?.toString() ?? '0'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bookings Over Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: FutureBuilder<QuerySnapshot>(
                                    future: _firestore
                                        .collectionGroup('bookings')
                                        .where('createdAt', isGreaterThanOrEqualTo: _startDate)
                                        .where('createdAt', isLessThanOrEqualTo: _endDate)
                                        .orderBy('createdAt')
                                        .get(),
                                    builder: (context, bookingSnapshot) {
                                      if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (!bookingSnapshot.hasData) {
                                        return const Center(child: Text('No booking data'));
                                      }
                                      final bookings = bookingSnapshot.data!.docs;
                                      final dataMap = <String, int>{};
                                      for (var doc in bookings) {
                                        final date = (doc['createdAt'] as Timestamp).toDate().toIso8601String().split('T')[0];
                                        dataMap[date] = (dataMap[date] ?? 0) + 1;
                                      }
                                      return _buildChart('bar', dataMap);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(String type, Map<String, int> dataMap) {
    final labels = dataMap.keys.toList();
    final values = dataMap.values.toList();
    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: CodeBlock(
                type: 'chartjs',
                content: '''
{
  "type": "$type",
  "data": {
    "labels": $labels,
    "datasets": [{
      "label": "Bookings",
      "data": $values,
      "backgroundColor": ["#4CAF50", "#FF9800", "#F44336", "#2196F3", "#9C27B0"],
      "borderColor": ["#4CAF50", "#FF9800", "#F44336", "#2196F3", "#9C27B0"],
      "borderWidth": 1
    }]
  },
  "options": {
    "scales": {
      "y": {
        "beginAtZero": true
      }
    }
  }
}
                ''',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// custom widget to handle chart display
class CodeBlock extends StatelessWidget {
  final String type;
  final String content;

  const CodeBlock({required this.type, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(content), // Placeholder; actual chart rendering would be handled by a chart library
    );
  }
}