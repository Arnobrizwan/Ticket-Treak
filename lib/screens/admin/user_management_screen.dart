import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showEditUserDialog(String userId, Map<String, dynamic> userData) {
    final _formKey = GlobalKey<FormState>();
    String name = userData['name'] ?? '';
    String email = userData['email'] ?? '';
    String role = userData['role'] ?? 'User';
    bool isActive = userData['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
                onChanged: (value) => name = value,
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
                onChanged: (value) => email = value,
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Admin', 'User']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => role = value!),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
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
                _firestore.collection('users').doc(userId).update({
                  'name': name,
                  'email': email,
                  'role': role,
                  'isActive': isActive,
                }).then((_) => Navigator.pop(context));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('users').doc(userId).delete().then((_) => Navigator.pop(context));
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('name', isGreaterThanOrEqualTo: _searchQuery)
                  .where('name', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found'));
                }
                final users = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final isActive = user['isActive'] ?? true;
                    final role = user['role'] ?? 'User';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['profileImage'] != null
                              ? NetworkImage(user['profileImage'] as String)
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                          child: user['profileImage'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(user['name'] ?? 'N/A'),
                        subtitle: Text(user['email'] ?? 'N/A'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Role: $role', style: TextStyle(color: Colors.grey)),
                            Text('Status: ${isActive ? 'Active' : 'Inactive'}',
                                style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                          ],
                        ),
                        onTap: () => _showEditUserDialog(userId, user),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditUserDialog(userId, user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteUser(userId),
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
        ],
      ),
    );
  }
}