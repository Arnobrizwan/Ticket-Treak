// lib/screens/user/flight/flight_detail_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightDetailScreen extends StatefulWidget {
  const FlightDetailScreen({Key? key}) : super(key: key);

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> {
  // Violin color palette (same as FlightSearchPage and FlightResultsPage)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor      = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor    = Color(0xFF8B5000); // Amber Brown
  static const Color textColor         = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey        = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey          = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange      = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen       = Color(0xFFB28F5E); // Muted Brown

  late final Map<String, dynamic> _offer;
  late final String _originCode;
  late final String _destinationCode;
  late final String _departureDateStr;
  late final int    _adults;
  late final String _travelClass;
  late final bool   _direct;
  late final bool   _isStudentFare;

  bool _isSaving = false;
  bool _alreadySaved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 1) Read the entire offer (and search metadata) passed via Navigator:
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _offer            = args['offer']            as Map<String, dynamic>;
    _originCode       = args['originCode']       as String;
    _destinationCode  = args['destinationCode']  as String;
    _departureDateStr = args['departureDate']    as String;
    _adults           = args['adults']           as int;
    _travelClass      = args['travelClass']      as String;
    _direct           = args['direct']           as bool;
    _isStudentFare    = args['isStudentFare']    as bool;

    // 2) Check if this offer is already saved in Firestore for this user:
    _checkIfAlreadySaved();
  }

  Future<void> _checkIfAlreadySaved() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('savedFlights')
        .where('userId', isEqualTo: userId)
        .where('offerId', isEqualTo: _offer['id'])
        .get();

    setState(() {
      _alreadySaved = snapshot.docs.isNotEmpty;
    });
  }

  Future<void> _saveCurrentOffer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // We store a minimal set of identifying fields (offer ID + the raw JSON)
      await FirebaseFirestore.instance.collection('savedFlights').add({
        'userId'           : user.uid,
        'offerId'          : _offer['id'], 
        'rawOfferJson'     : _offer,     // entire map is serializable
        'originCode'       : _originCode,
        'destinationCode'  : _destinationCode,
        'departureDateStr' : _departureDateStr,
        'adults'           : _adults,
        'travelClass'      : _travelClass,
        'direct'           : _direct,
        'isStudentFare'    : _isStudentFare,
        'savedAt'          : FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaving = false;
        _alreadySaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Flight saved successfully.'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving flight: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Parse total price & currency:
    final priceInfo  = _offer['price'] as Map<String, dynamic>;
    final totalPrice = priceInfo['total'] as String;
    final currency   = priceInfo['currency'] as String;

    // 2) We’ll iterate through every itinerary & segment in the offer,
    //    and display all of them.
    final itineraries = _offer['itineraries'] as List<dynamic>;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Details: $_originCode → $_destinationCode",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── OFFER HEADER ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Offer ID: ${_offer['id']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentOrange.darken(0.2),
                    ),
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
            ),
            const SizedBox(height: 16),

            // ─── ITINERARIES & SEGMENTS ───────────────────────────────────
            ...List.generate(itineraries.length, (itinIndex) {
              final singleItin = itineraries[itinIndex] as Map<String, dynamic>;
              final durationStr = singleItin['duration'] as String;
              final segments    = singleItin['segments'] as List<dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Itinerary header
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Itinerary ${itinIndex + 1}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 18, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(durationStr),
                              style: TextStyle(color: darkGrey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Each segment in this itinerary:
                  ...List.generate(segments.length, (segIndex) {
                    final seg = segments[segIndex] as Map<String, dynamic>;
                    final dep = seg['departure'] as Map<String, dynamic>;
                    final arr = seg['arrival']   as Map<String, dynamic>;
                    final carrier  = seg['carrierCode'] as String;
                    final flightNo = seg['number'] as String;
                    final depAt    = DateTime.parse(dep['at'] as String);
                    final arrAt    = DateTime.parse(arr['at'] as String);

                    final depTimeFmt = DateFormat('hh:mm a').format(depAt);
                    final depDateFmt = DateFormat('MMM dd').format(depAt);
                    final arrTimeFmt = DateFormat('hh:mm a').format(arrAt);
                    final arrDateFmt = DateFormat('MMM dd').format(arrAt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Row: Carrier / FlightNo
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
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row: Departure Info → Icon → Arrival Info
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
                                      fontSize: 18,
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

                              // Duration icon
                              Column(
                                children: [
                                  const Icon(Icons.schedule, size: 20, color: primaryColor),
                                  const SizedBox(width: 4),
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
                                      fontSize: 18,
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
                        ],
                      ),
                    );
                  }),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ─── SAVE BUTTON ──────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: (_alreadySaved || _isSaving) ? null : _saveCurrentOffer,
              icon: Icon(
                _alreadySaved ? Icons.check : Icons.bookmark_border,
                color: Colors.white,
              ),
              label: Text(
                _alreadySaved ? "Already Saved" : (_isSaving ? "Saving…" : "Save This Flight"),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _alreadySaved ? Colors.grey : primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Converts ISO-8601 “PT#H#M” → “2h 45m”, etc.
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

/// Simple Color extension to darken a color by a fraction
extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl    = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}