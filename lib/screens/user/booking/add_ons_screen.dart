import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> {
  // Color palette from LoginScreen
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  double _baggageCost = 0.0;
  double _mealCost = 0.0;
  bool _insuranceSelected = false;
  double _totalAddOns = 0.0;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _updateTotal(); // Initialize total
  }

  // Calculate total add-ons
  void _updateTotal() {
    setState(() {
      _totalAddOns = _baggageCost + _mealCost + (_insuranceSelected ? 10.0 : 0.0); // Insurance mocked at $10
    });
  }

  // Save add-ons to Firestore
  Future<void> _saveAddOns() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('bookings').doc().set({
          'userId': user.uid,
          'flight': {'code': 'AK123', 'route': 'KUL-BKK', 'duration': '2h 10min'},
          'addons': {
            'baggage': _baggageCost,
            'meal': _mealCost,
            'insurance': _insuranceSelected ? 10.0 : 0.0,
            'total': _totalAddOns,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add-ons saved successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          // Navigate to Passenger Details page
          Navigator.pushNamed(context, AppRoutes.passengerDetails);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving add-ons: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to continue.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: Column(
            children: [
              // Back to Seat Selection
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context); // Go back to previous page
                        },
                  icon: Icon(Icons.arrow_back, color: primaryColor),
                  label: Text(
                    'Back to Seat Selection',
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                ),
              ),
              // Header
              Text(
                'Customize Your Flight',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              // Flight Details
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: subtleGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'AK123 | KUL-BKK | Duration: 2h 10min',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checked Baggage
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Checked Baggage',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<double>(
                              value: _baggageCost,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: [
                                DropdownMenuItem(value: 0.0, child: Text('None (\$0)')),
                                DropdownMenuItem(value: 12.0, child: Text('20kg - \$12')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _baggageCost = value!;
                                  _updateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Meal Selection
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meal Selection',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Nasi Lemak
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _mealCost = 4.0;
                                      _updateTotal();
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Image.network(
                                        'https://via.placeholder.com/100?text=Nasi+Lemak',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Nasi Lemak',
                                        style: TextStyle(color: textColor),
                                      ),
                                      Text(
                                        '\$4.00',
                                        style: TextStyle(color: Colors.green[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                // Chicken Rice
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _mealCost = 4.5;
                                      _updateTotal();
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Image.network(
                                        'https://via.placeholder.com/100?text=Chicken+Rice',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Chicken Rice',
                                        style: TextStyle(color: textColor),
                                      ),
                                      Text(
                                        '\$4.50',
                                        style: TextStyle(color: Colors.green[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                // Vegetarian Pasta
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _mealCost = 4.0;
                                      _updateTotal();
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Image.network(
                                        'https://via.placeholder.com/100?text=Vegetarian+Pasta',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Vegetarian Pasta',
                                        style: TextStyle(color: textColor),
                                      ),
                                      Text(
                                        '\$4.00',
                                        style: TextStyle(color: Colors.green[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Travel Insurance
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Travel Insurance',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Basic coverage (including delays, cancellations)',
                                  style: TextStyle(fontSize: 14, color: darkGrey),
                                ),
                              ],
                            ),
                            Switch(
                              value: _insuranceSelected,
                              onChanged: (value) {
                                setState(() {
                                  _insuranceSelected = value;
                                  _updateTotal();
                                });
                              },
                              activeColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Total Add-Ons
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Add-Ons:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '\$${_totalAddOns.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddOns,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(50),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}