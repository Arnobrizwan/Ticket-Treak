import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart'; // adjust path if needed


class SavedFlightsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> savedFlights = [
    {
      'from': 'KUL',
      'to': 'CGK',
      'price': 120,
      'time': '08:00',
      'airline': 'Lion Air',
      'logo': Icons.flight, // Replace with Image if you want
    },
    {
      'from': 'SIN',
      'to': 'HND',
      'price': 350,
      'time': '10:30',
      'airline': 'ANA',
      'logo': Icons.flight,
    },
    {
      'from': 'Mex',
      'to': 'SFO',
      'price': 220,
      'time': '09:15',
      'airline': 'United',
      'logo': Icons.flight,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Flights')),
      body: ListView.builder(
        itemCount: savedFlights.length,
        itemBuilder: (context, index) {
          final flight = savedFlights[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(flight['logo']),
              title: Text('${flight['from']} → ${flight['to']}'),
              subtitle: Text('${flight['airline']} • \$${flight['price']} • ${flight['time']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                          AppRoutes.flightResults,                        arguments: {
                          'from': flight['from'],
                          'to': flight['to'],
                        },
                      );
                    },
                    child: Text('Rebook'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Implement remove logic here if you want
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed flight')),
                      );
                    },
                    child: Text('Remove'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
