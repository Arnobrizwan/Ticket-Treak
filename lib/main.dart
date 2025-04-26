import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const TicketTrekApp());
}

class TicketTrekApp extends StatelessWidget {
  const TicketTrekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TicketTrek',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}


