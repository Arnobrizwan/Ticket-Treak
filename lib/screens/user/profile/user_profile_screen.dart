import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Color(0xFF3F3D9A), // Match your primary color
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture Section
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage('https://www.example.com/profile_picture.jpg'), // Use dynamic URL
              ),
            ),
            SizedBox(height: 20),
            // Profile Info Section
            Text('John Doe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('johndoe@example.com', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text('Frequent Flyer: Gold Status', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 40),
            // Edit Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/editProfile'); // Navigate to Edit Profile Screen
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                backgroundColor : Color(0xFF3F3D9A), // Match your primary color
              ),
              child: Text('Edit Profile', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
