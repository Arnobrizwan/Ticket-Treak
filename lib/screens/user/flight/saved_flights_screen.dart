// lib/screens/user/flight/saved_flights_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavedFlightsScreen extends StatefulWidget {
  const SavedFlightsScreen({Key? key}) : super(key: key);

  @override
  State<SavedFlightsScreen> createState() => _SavedFlightsScreenState();
}

class _SavedFlightsScreenState extends State<SavedFlightsScreen> {
  // Violin color palette (same as everywhere)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor      = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor    = Color(0xFF8B5000); // Amber Brown
  static const Color textColor         = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey        = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey          = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange      = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen       = Color(0xFFB28F5E); // Muted Brown

  late final String _userId;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';
  }

  Future<void> _refreshList() async {
    // Just trigger a rebuild; the StreamBuilder will automatically pick up changes.
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      // If no user is logged in, show placeholder
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: const Text("Saved Flights", style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: const Center(
          child: Text("Please log in to view saved flights."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Saved Flights", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshList,
        backgroundColor: primaryColor,
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('savedFlights')
              .where('userId', isEqualTo: _userId)
              .orderBy('savedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading saved flights: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(primaryColor),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.airplane_ticket, size: 48, color: subtleGrey),
                      const SizedBox(height: 16),
                      const Text(
                        "You have no saved flights yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Search New Flights",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Build a ListView of saved offers:
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc    = docs[index];
                final saved  = doc.data() as Map<String, dynamic>;
                final offer  = saved['rawOfferJson'] as Map<String, dynamic>;

                // Same parsing logic as in FlightResultsPage
                final priceInfo  = offer['price'] as Map<String, dynamic>;
                final totalPrice = priceInfo['total'] as String;
                final currency   = priceInfo['currency'] as String;

                final itineraries = offer['itineraries'] as List<dynamic>;
                final firstItin   = itineraries[0] as Map<String, dynamic>;
                final durationStr = firstItin['duration'] as String;
                final segments    = firstItin['segments'] as List<dynamic>;
                final firstSeg    = segments[0] as Map<String, dynamic>;
                final dep         = firstSeg['departure'] as Map<String, dynamic>;
                final arr         = firstSeg['arrival']   as Map<String, dynamic>;
                final carrier     = firstSeg['carrierCode'] as String;
                final flightNo    = firstSeg['number'] as String;
                final depAt       = DateTime.parse(dep['at'] as String);
                final arrAt       = DateTime.parse(arr['at'] as String);

                final depTimeFmt = DateFormat('hh:mm a').format(depAt);
                final arrTimeFmt = DateFormat('hh:mm a').format(arrAt);
                final depDateFmt = DateFormat('MMM dd').format(depAt);
                final arrDateFmt = DateFormat('MMM dd').format(arrAt);

                return Dismissible(
                  key: Key(doc.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    await _firestore.collection('savedFlights').doc(doc.id).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from saved flights.')),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top strip: “Saved Flight #…”
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: accentOrange.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Text(
                            "Saved Flight ${index + 1}",
                            style: TextStyle(
                              color: accentOrange.darken(0.2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Main content: departure‐arrival + price
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            children: [
                              // Row: Carrier → Flight No. → Price
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: primaryColor.withOpacity(0.2),
                                        child: Text(
                                          carrier,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$carrier $flightNo",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "$currency $totalPrice",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: accentGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Row: Departure → Duration → Arrival
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Departure
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        depTimeFmt,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${dep['iataCode']} • $depDateFmt",
                                        style: TextStyle(fontSize: 12, color: darkGrey),
                                      ),
                                    ],
                                  ),

                                  // Flight Duration
                                  Column(
                                    children: [
                                      Icon(Icons.schedule, color: primaryColor, size: 20),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDuration(durationStr),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: darkGrey,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Arrival
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        arrTimeFmt,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${arr['iataCode']} • $arrDateFmt",
                                        style: TextStyle(fontSize: 12, color: darkGrey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // “Details” button navigates back into FlightDetailScreen
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/flight-detail',
                                      arguments: {
                                        'offer': offer,
                                        'originCode': saved['originCode'] as String,
                                        'destinationCode': saved['destinationCode'] as String,
                                        'departureDate': saved['departureDateStr'] as String,
                                        'adults': saved['adults'] as int,
                                        'travelClass': saved['travelClass'] as String,
                                        'direct': saved['direct'] as bool,
                                        'isStudentFare': saved['isStudentFare'] as bool,
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text("Details"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryColor,           // replaced `primary:` with `foregroundColor:`
                                    side: BorderSide(color: primaryColor),     // keep the outline in the same color
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Converts ISO-8601 “PT#H#M” → “2h 45m”
  String _formatDuration(String isoDuration) {
    final regex = RegExp(r'PT(\d+)H(\d+)M');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final hours   = match.group(1)!;
      final minutes = match.group(2)!;
      return "${hours}h ${minutes}m";
    }
    return isoDuration.replaceFirst("PT", "").replaceAll("H", "h ").replaceAll("M", "m");
  }
}

// Color extension to darken a color by [amount]:
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl   = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}