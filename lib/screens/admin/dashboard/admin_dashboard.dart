import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now(); // Saturday, June 14, 2025, 08:56 AM +08

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 80,
            color: const Color(0xFF2D3142),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildNavItem(Icons.flight, 'Flights', AppRoutes.flightManagement),
                _buildNavItem(Icons.book, 'Bookings', AppRoutes.bookingManagement),
                _buildNavItem(Icons.receipt, 'Refunds', AppRoutes.refundRequests),
                _buildNavItem(Icons.people, 'Users', AppRoutes.userManagement),
                _buildNavItem(Icons.settings, 'Settings', AppRoutes.settings),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDashboardCard(
                        title: 'Total Bookings',
                        stream: _firestore.collection('bookings').snapshots(),
                        valueBuilder: (snapshot) => snapshot.docs.length.toString(),
                        child: Container(
                          height: 50,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF3F3D9A), Color(0xFF6C63FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      _buildDashboardCard(
                        title: "Today's Flights",
                        stream: _firestore
                            .collection('flights')
                            .where('departureDate',
                                isEqualTo: DateTime(currentDate.year, currentDate.month, currentDate.day))
                            .snapshots(),
                        valueBuilder: (snapshot) => snapshot.docs.length.toString(),
                      ),
                      _buildDashboardCard(
                        title: 'Active Refund Requests',
                        stream: _firestore
                            .collection('refund_requests')
                            .where('status', whereIn: ['pending', 'under_review'])
                            .snapshots(),
                        valueBuilder: (snapshot) => snapshot.docs.length.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required Stream<QuerySnapshot> stream,
    required String Function(QuerySnapshot snapshot) valueBuilder,
    Widget? child,
  }) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142))),
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(color: Color(0xFF3F3D9A)),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return Column(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142))),
                    const SizedBox(height: 8),
                    const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                );
              }
              final value = valueBuilder(snapshot.data!);
              return Column(
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3142))),
                  const SizedBox(height: 8),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (child != null) child,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}