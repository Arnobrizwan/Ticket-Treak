// File: lib/screens/user/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_routes.dart';

// ---------------------------------------------------------------------------
// A fully redesigned, enterprise-grade Registration Screen for Flutter.
// Matches the “violin” color palette and UI style of the Login Screen.
// ---------------------------------------------------------------------------

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // “Violin” palette (matching Login & Onboarding)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown (wood grain)
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood (almost black)
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange    = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown

  double _opacity = 0.0;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final TextEditingController _nameController     = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _phoneController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController  = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fade in effect for the form
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        (_passwordController.text == _confirmController.text) &&
        _termsAccepted;
  }

  Future<void> _registerWithFirebase() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields and accept terms"),
          backgroundColor: accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user with email & password
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!
            .updateDisplayName(_nameController.text.trim());

        // Save profile in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name':      _nameController.text.trim(),
          'email':     _emailController.text.trim(),
          'phone':     _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Account created successfully! Please verify your email."
              ),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Navigate to Login Screen
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = _getFirebaseErrorMessage(e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration failed: ${e.toString()}"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  void _submitForm() {
    _registerWithFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ─────────────────────────────────────────────────────────────────────
          // Background Image with Gradient Overlay
          // ─────────────────────────────────────────────────────────────────────
          CachedNetworkImage(
            imageUrl:
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e'
              '?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: subtleGrey,
            ),
            errorWidget: (context, url, error) => Container(
              color: subtleGrey,
              child: const Icon(
                Icons.flight,
                size: 80,
                color: Colors.white30,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withOpacity(0.75),
                  primaryColor.withOpacity(0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────────
          // Main Content: Center Card + Logo + Form
          // ─────────────────────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─────────────────────────────────────────────────────
                      // Logo / App Emblem Container
                      // ─────────────────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flight_takeoff,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─────────────────────────────────────────────────────
                      // Card containing the Registration Form
                      // ─────────────────────────────────────────────────────
                      Card(
                        color: Colors.white.withOpacity(0.95),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // ───────────────────────────────────────────────
                              // Title & Subtitle
                              // ───────────────────────────────────────────────
                              Text(
                                'Create Your Account',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join TicketTrek and start exploring!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: darkGrey,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // ───────────────────────────────────────────────
                              // Full Name Field
                              // ───────────────────────────────────────────────
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.person_outline, color: darkGrey),
                                  labelText: 'Full Name',
                                  labelStyle: TextStyle(color: darkGrey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Email Field
                              // ───────────────────────────────────────────────
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined, color: darkGrey),
                                  labelText: 'Email',
                                  labelStyle: TextStyle(color: darkGrey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Phone Field
                              // ───────────────────────────────────────────────
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.phone_outlined, color: darkGrey),
                                  labelText: 'Phone',
                                  labelStyle: TextStyle(color: darkGrey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Password Field
                              // ───────────────────────────────────────────────
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline, color: darkGrey),
                                  labelText: 'Password',
                                  labelStyle: TextStyle(color: darkGrey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                      color: darkGrey,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Confirm Password Field
                              // ───────────────────────────────────────────────
                              TextField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                style: const TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.lock_outline, color: darkGrey),
                                  labelText: 'Confirm Password',
                                  labelStyle: TextStyle(color: darkGrey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: subtleGrey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                      color: darkGrey,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Terms & Conditions Checkbox
                              // ───────────────────────────────────────────────
                              Row(
                                children: [
                                  Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (value) => setState(
                                      () => _termsAccepted = value ?? false),
                                    activeColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      "I accept the Terms & Conditions",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: null,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // ───────────────────────────────────────────────
                              // Create Account Button
                              // ───────────────────────────────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
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
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ───────────────────────────────────────────────
                              // “Already have an account? Sign In” Link
                              // ───────────────────────────────────────────────
                              TextButton(
                                onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacementNamed(
                                      context, AppRoutes.login),
                                style: TextButton.styleFrom(
                                  foregroundColor: primaryColor,
                                ),
                                child: const Text(
                                  "Already have an account? Sign In",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}