import 'package:flutter/material.dart';

class FlightDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use hardcoded demo data or replace with ModalRoute for dynamic
    final flightNo = 'AK123';
    final route = 'Kuala Lumpur to Bangkok';
    final depTime = '10:00';
    final arrTime = '11:15';
    final duration = '2h 15m';
    final depAirport = 'KUL Terminal 2';
    final arrAirport = 'BKK Terminal 1';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Flight Detail Page',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Container(
          width: 370,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 34),
              // Airline Logo removed
              // Flight Number
              Text(
                flightNo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              // Route
              Text(
                route,
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 0.3,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Flight Segments Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: Colors.blue.shade50,
                child: const Text(
                  "Flight Segments",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),

              // Segment Times
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Departure
                    Column(
                      children: [
                        Text(depTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(depAirport, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    // Duration
                    Column(
                      children: [
                        Text(duration, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      ],
                    ),
                    // Arrival
                    Column(
                      children: [
                        Text(arrTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(arrAirport, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              // Divider
              Container(height: 1, color: Colors.blue.shade100),

              // Clickable List Items
              _flightOption("Baggage Allowance", () {}),
              _flightOption("In-Flight Services", () {}),
              _flightOption("Refund & Reschedule Policy", () {}),
              // Divider
              Container(height: 1, color: Colors.blue.shade100),

              // Pricing Breakdown Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                color: Colors.blue.shade50,
                child: const Text(
                  "Pricing Breakdown",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    _priceRow("Base Fare", "\$100"),
                    _priceRow("Taxes", "\$32"),
                    _priceRow("Service Fees", "\$8"),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              // Select Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Booking Confirmed"),
                          content: const Text("You have selected this flight."),
                        ),
                      );
                    },
                    child: const Text('Select', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Clickable flight option row
  Widget _flightOption(String title, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              const Icon(Icons.chevron_right, size: 24, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Price row
  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        ],
      ),
    );
  }
}
