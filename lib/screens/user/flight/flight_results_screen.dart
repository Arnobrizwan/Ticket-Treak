import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart'; // adjust path if needed



class FlightResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final from = args != null ? args['from'] : 'KUL';
    final to = args != null ? args['to'] : 'BKK';

    final List<Map<String, dynamic>> flights = [
      {
        'airline': 'Lion Air',
        'flightNo': 'AK 123',
        'time': '08:25',
        'price': 90,
        'duration': '1h 25m',
      },
      {
        'airline': 'MAS',
        'flightNo': 'MH 456',
        'time': '09:15',
        'price': 140,
        'duration': '2h 15m',
      },
      {
        'airline': 'Singapore Airlines',
        'flightNo': 'SQ 101',
        'time': '13:55',
        'price': 180,
        'duration': '2h 15m',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text('$from to $to')),
      body: ListView.builder(
        itemCount: flights.length,
        itemBuilder: (context, index) {
          final flight = flights[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text('${flight['airline']} ${flight['flightNo']}'),
              subtitle: Text('${flight['duration']} | ${flight['time']} | \$${flight['price']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.flightDetail,
                    arguments: flight,
                  );
                },
                child: Text('Select'),
              ),
            ),
          );
        },
      ),
    );
  }
}
