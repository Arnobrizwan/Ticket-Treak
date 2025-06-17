import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class FlightManagementScreen extends StatefulWidget {
  const FlightManagementScreen({super.key});

  @override
  State<FlightManagementScreen> createState() => _FlightManagementScreenState();
}

class _FlightManagementScreenState extends State<FlightManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _showEditFlightDialog(String flightId, Map<String, dynamic> flightData) {
    final _formKey = GlobalKey<FormState>();
    String flightCode = flightData['flightCode'] ?? '';
    String origin = flightData['origin'] ?? '';
    String destination = flightData['destination'] ?? '';
    String departureTime = flightData['departureTime'] ?? '';
    String status = flightData['status'] ?? 'Scheduled';
    String arrivalTime = flightData['arrivalTime'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Flight'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: flightCode,
                  decoration: const InputDecoration(labelText: 'Flight Code'),
                  validator: (value) => value!.isEmpty ? 'Enter flight code' : null,
                  onChanged: (value) => flightCode = value,
                ),
                TextFormField(
                  initialValue: origin,
                  decoration: const InputDecoration(labelText: 'Origin'),
                  validator: (value) => value!.isEmpty ? 'Enter origin' : null,
                  onChanged: (value) => origin = value,
                ),
                TextFormField(
                  initialValue: destination,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  validator: (value) => value!.isEmpty ? 'Enter destination' : null,
                  onChanged: (value) => destination = value,
                ),
                TextFormField(
                  initialValue: departureTime,
                  decoration: const InputDecoration(labelText: 'Departure Time'),
                  validator: (value) => value!.isEmpty ? 'Enter departure time' : null,
                  onChanged: (value) => departureTime = value,
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Scheduled', 'Delayed', 'Canceled']
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => status = value!),
                ),
                TextFormField(
                  initialValue: arrivalTime,
                  decoration: const InputDecoration(labelText: 'Arrival Time'),
                  validator: (value) => value!.isEmpty ? 'Enter arrival time' : null,
                  onChanged: (value) => arrivalTime = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _firestore.collection('flights').doc(flightId).update({
                  'flightCode': flightCode,
                  'origin': origin,
                  'destination': destination,
                  'departureTime': departureTime,
                  'status': status,
                  'arrivalTime': arrivalTime,
                }).then((_) => Navigator.pop(context));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddFlightDialog() {
    final _formKey = GlobalKey<FormState>();
    String flightCode = '';
    String origin = '';
    String destination = '';
    String departureTime = '';
    String status = 'Scheduled';
    String arrivalTime = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Flight'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Flight Code'),
                  validator: (value) => value!.isEmpty ? 'Enter flight code' : null,
                  onChanged: (value) => flightCode = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Origin'),
                  validator: (value) => value!.isEmpty ? 'Enter origin' : null,
                  onChanged: (value) => origin = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Destination'),
                  validator: (value) => value!.isEmpty ? 'Enter destination' : null,
                  onChanged: (value) => destination = value,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Departure Time'),
                  validator: (value) => value!.isEmpty ? 'Enter departure time' : null,
                  onChanged: (value) => departureTime = value,
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: ['Scheduled', 'Delayed', 'Canceled']
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => status = value!),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Arrival Time'),
                  validator: (value) => value!.isEmpty ? 'Enter arrival time' : null,
                  onChanged: (value) => arrivalTime = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _firestore.collection('flights').add({
                  'flightCode': flightCode,
                  'origin': origin,
                  'destination': destination,
                  'departureTime': departureTime,
                  'status': status,
                  'arrivalTime': arrivalTime,
                  'createdAt': FieldValue.serverTimestamp(),
                }).then((_) => Navigator.pop(context));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
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
        title: const Text('Flight Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('flights').orderBy('departureTime').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No flights available'));
          }
          final flights = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: flights.length + 1,
            itemBuilder: (context, index) {
              if (index == flights.length) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _showAddFlightDialog,
                      child: const Text('Add New Flight'),
                    ),
                  ],
                );
              }
              final flight = flights[index].data() as Map<String, dynamic>;
              final flightId = flights[index].id;
              final statusColor = {
                'Scheduled': Colors.green,
                'Delayed': Colors.orange,
                'Canceled': Colors.red,
              }[flight['status'] ?? 'Scheduled'] ?? Colors.green;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(flight['flightCode'] ?? 'N/A'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${flight['origin'] ?? 'N/A'} → ${flight['destination'] ?? 'N/A'}'),
                      Text('${flight['departureTime'] ?? 'N/A'}'),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(flight['arrivalTime'] ?? 'N/A'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          flight['status'] ?? 'Scheduled',
                          style: TextStyle(color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showEditFlightDialog(flightId, flight),
                ),
              );
            },
          );
        },
      ),
    );
  }
}