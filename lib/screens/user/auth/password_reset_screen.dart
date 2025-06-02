// File: lib/screens/user/auth/password_reset_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_routes.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  // “Violin” palette (same as Login/Registration)
  static const Color backgroundColor = Color(0xFFF5F0E1);  // Ivory
  static const Color primaryColor    = Color(0xFF5C2E00);  // Dark Brown (wood grain)
  static const Color secondaryColor  = Color(0xFF8B5000);  // Amber Brown
  static const Color textColor       = Color(0xFF35281E);  // Deep Wood (almost black)
  static const Color subtleGrey      = Color(0xFFDAC1A7);  // Light Tan
  static const Color darkGrey        = Color(0xFF7E5E3C);  // Medium Brown
  static const Color accentOrange    = Color(0xFFD4A373);  // Warm Highlight
  static const Color accentGreen     = Color(0xFFB28F5E);  // Muted Brown

  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade‐in the form card
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Validate that the string is a properly formatted email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(email);
  }

  /// Map Firebase password reset errors to user‐friendly messages
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Failed to send reset email. Please try again.';
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Trigger Firebase password reset email
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address', accentOrange);
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address', accentOrange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      _showSnackBar(
        'Password reset email sent! Check your inbox.',
        accentGreen,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      final msg = _getFirebaseErrorMessage(e.code);
      _showSnackBar(msg, Colors.red.shade700);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(
        'Failed to send reset email: ${e.toString()}',
        Colors.red.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ─────────────────────────────────────────────────────────────────────
          // Full‐screen Background Image (same as Login)
          // ─────────────────────────────────────────────────────────────────────
          CachedNetworkImage(
            imageUrl:
                'https://images.unsplash.com/photo-1507525428034-b723cf961d3e'
                '?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(color: subtleGrey),
            errorWidget: (context, url, error) => Container(
              color: subtleGrey,
              child: const Center(
                child: Icon(
                  Icons.flight_takeoff,
                  size: 80,
                  color: Colors.white30,
                ),
              ),
            ),
          ),

          // Semi‐transparent “violin” gradient overlay
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
          // Main Content: frosted‐glass card + icon + form
          // ─────────────────────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ───────────────────────────────────────────────────────
                      // Circular Icon at top
                      // ───────────────────────────────────────────────────────
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
                          _emailSent
                              ? Icons.mark_email_read
                              : Icons.lock_reset,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ───────────────────────────────────────────────────────
                      // Frosted‐glass Card
                      // ───────────────────────────────────────────────────────
                      Card(
                        color: Colors.white.withOpacity(0.95),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // ───────────────────────────────────────────────
                                // Title & Subtitle
                                // ───────────────────────────────────────────────
                                Text(
                                  _emailSent
                                      ? 'Check Your Email'
                                      : 'Reset Password',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _emailSent
                                      ? 'We’ve sent instructions to your email.'
                                      : 'Enter your email to receive reset instructions',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                if (!_emailSent) ...[
                                  // ───────────────────────────────────────────
                                  // Email TextField
                                  // ───────────────────────────────────────────
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: darkGrey,
                                      ),
                                      labelText: 'Email Address',
                                      labelStyle: TextStyle(color: darkGrey),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: subtleGrey),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: subtleGrey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: primaryColor, width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: Colors.red),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter Email';
                                      }
                                      if (!_isValidEmail(value.trim())) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  // ───────────────────────────────────────────
                                  // Send Reset Email Button
                                  // ───────────────────────────────────────────
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              if (!_formKey
                                                  .currentState!
                                                  .validate()) return;
                                              _sendPasswordResetEmail();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Send Reset Email',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ] else ...[
                                  // ───────────────────────────────────────────
                                  // Success State (Email Sent)
                                  // ───────────────────────────────────────────
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Email Sent Successfully!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Check your inbox and follow the instructions to reset your password.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // ───────────────────────────────────────────────
                                // “Back to Sign In” Link (always shown)
                                // ───────────────────────────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.pushReplacementNamed(
                                                context, AppRoutes.login);
                                          },
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: primaryColor,
                                    ),
                                    label: Text(
                                      _emailSent
                                          ? 'Back to Sign In'
                                          : 'Remembered your password? Sign In',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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