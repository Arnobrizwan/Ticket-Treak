import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class RefundRequestsScreen extends StatefulWidget {
  const RefundRequestsScreen({super.key});

  @override
  State<RefundRequestsScreen> createState() => _RefundRequestsScreenState();
}

class _RefundRequestsScreenState extends State<RefundRequestsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _filter = 'All';

  void _showIssueRefundDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: const Text('Are you sure you want to issue this refund?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('refund_requests').doc(requestId).update({
                'status': 'Processed',
                'processedAt': FieldValue.serverTimestamp(),
              }).then((_) => Navigator.pop(context));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRequestDialog(String requestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('refund_requests').doc(requestId).delete().then((_) => Navigator.pop(context));
            },
            child: const Text('Yes'),
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
        title: const Text('Refund Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _filter,
              onChanged: (String? newValue) {
                setState(() {
                  _filter = newValue!;
                });
              },
              items: <String>['All', 'Pending', 'Processed']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _filter == 'All'
            ? _firestore.collection('refund_requests').orderBy('createdAt', descending: true).snapshots()
            : _firestore
                .collection('refund_requests')
                .where('status', isEqualTo: _filter)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No refund requests available'));
          }
          final requests = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;
              final statusColor = {
                'Pending': Colors.green,
                'Processed': Colors.purple,
              }[request['status'] ?? 'Pending'] ?? Colors.green;
              final isPending = request['status'] == 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Text('#${requestId.substring(0, 8)}'),
                  title: Text(request['passengerName'] ?? 'N/A'),
                  subtitle: Text('${request['flightCode'] ?? 'N/A'} → ${request['origin'] ?? 'N/A'} > ${request['destination'] ?? 'N/A'}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request['status'] ?? 'Pending',
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.bookingDetail,
                    arguments: request['bookingId'],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.bookingDetail,
                          arguments: request['bookingId'],
                        ),
                        child: const Text('View Details'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isPending
                            ? () => _showIssueRefundDialog(requestId)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending ? Colors.green : Colors.grey,
                        ),
                        child: const Text('Issue Refund'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteRequestDialog(requestId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}