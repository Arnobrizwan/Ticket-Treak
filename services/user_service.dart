import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Create user profile in Firestore
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'profilePicture': null,
        'preferences': {
          'notifications': true,
          'emailUpdates': true,
          'darkMode': false,
        },
        'travelInfo': {
          'frequentFlyerNumbers': [],
          'preferredAirlines': [],
          'seatPreference': 'aisle',
          'mealPreference': 'regular',
        },
      });
      
      // Load the user data after creation
      await loadUserData(uid);
    } catch (e) {
      rethrow;
    }
  }
  
  // Load user data from Firestore
  Future<void> loadUserData(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>?;
      } else {
        _userData = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    try {
      if (currentUserId == null) return;
      
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(currentUserId).update(data);
      
      // Update local userData
      if (_userData != null) {
        _userData!.addAll(data);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Update last login timestamp
  Future<void> updateLastLogin() async {
    try {
      if (currentUserId == null) return;
      
      await _firestore.collection('users').doc(currentUserId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await updateUserProfile({'preferences': preferences});
    } catch (e) {
      rethrow;
    }
  }
  
  // Update travel information
  Future<void> updateTravelInfo(Map<String, dynamic> travelInfo) async {
    try {
      await updateUserProfile({'travelInfo': travelInfo});
    } catch (e) {
      rethrow;
    }
  }
  
  // Add flight booking to user's history
  Future<void> addFlightBooking(Map<String, dynamic> bookingData) async {
    try {
      if (currentUserId == null) return;
      
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookings')
          .add({
        ...bookingData,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // Get user's flight bookings
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      if (currentUserId == null) return [];
      
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Stream user data (real-time updates)
  Stream<DocumentSnapshot> getUserDataStream() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(currentUserId).snapshots();
  }
  
  // Delete user data
  Future<void> deleteUserData() async {
    try {
      if (currentUserId == null) return;
      
      // Delete user bookings
      QuerySnapshot bookings = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('bookings')
          .get();
      
      for (DocumentSnapshot doc in bookings.docs) {
        await doc.reference.delete();
      }
      
      // Delete user profile
      await _firestore.collection('users').doc(currentUserId).delete();
      
      _userData = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // Clear local user data (for logout)
  void clearUserData() {
    _userData = null;
    _isLoading = false;
    notifyListeners();
  }
}