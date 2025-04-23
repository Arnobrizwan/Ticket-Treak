// import 'package:flutter/material.dart';
// import 'routes/app_routes.dart';

// void main() {
//   runApp(const TicketTrekApp());
// }

// class TicketTrekApp extends StatelessWidget {
//   const TicketTrekApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'TicketTrek',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
//         useMaterial3: true,
//       ),
//       initialRoute: AppRoutes.splash,
//       routes: AppRoutes.routes,
//     );
//   }
// }


import 'package:flutter/material.dart';

void main() => runApp(TicketTrekApp());

class TicketTrekApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicketTrek Wireframe',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ScreenList(),
    );
  }
}

class ScreenList extends StatelessWidget {
  final List<String> screens = [
    'Splash Screen',
    'Welcome / Onboarding Screen',
    'Login Page',
    'Registration Page',
    'Password Reset Page',
    'Home Dashboard',
    'Flight Search Page',
    'Saved Flights Page',
    'Flight Results Page',
    'Flight Detail Page',
    'Seat Selection Page',
    'Add-Ons Page',
    'Passenger Details Page',
    'Payment Page',
    'Payment Success Page',
    'Booking Confirmation Page',
    'My Bookings Page',
    'Booking Detail Page',
    'Cancel Booking Page',
    'Refund Status Page',
    'User Profile Page',
    'Edit Profile Page',
    'Settings Page',
    'Support / Help Page',
    'Error Page',
    'No Data Page',
    'No Connection Page',
    'Admin Login Page',
    'Admin Dashboard',
    'Flight Management Page',
    'Booking Management Page',
    'Refund Requests Page',
    'Admin Analytics Page'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TicketTrek Screens')),
      body: ListView.builder(
        itemCount: screens.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(screens[index]),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DummyUIScreen(screenName: screens[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DummyUIScreen extends StatelessWidget {
  final String screenName;

  DummyUIScreen({required this.screenName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(screenName)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.airplanemode_active, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(screenName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Divider(height: 30),
            Expanded(
              child: ListView(
                children: [
                  Text("This is the wireframe layout for $screenName.",
                      style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Placeholder(fallbackHeight: 300),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Simulate Action'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
