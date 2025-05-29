import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/app_routes.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  double _opacity = 0;
  bool _isLoading = false;
  bool _emailSent = false;
  
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Enterprise color palette (matching register screen)
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Send password reset email
  Future<void> _sendPasswordResetEmail() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email address', Colors.orange);
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      _showSnackBar(
        'Password reset email sent! Check your inbox.',
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage = _getFirebaseErrorMessage(e.code);
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Failed to send reset email: ${e.toString()}', Colors.red);
    }
  }

  // Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Helper method for Firebase error messages
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

  // Helper method for snackbars
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 600),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 80),
                      
                      // App Icon
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: _emailSent ? Colors.green : primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (_emailSent ? Colors.green : primaryColor).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Title
                      Text(
                        _emailSent ? 'Check Your Email' : 'Reset Password',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Subtitle
                      Text(
                        _emailSent 
                          ? 'We\'ve sent password reset instructions to your email'
                          : 'Enter your email to receive reset instructions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: darkGrey,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      if (!_emailSent) ...[
                        // Email Input Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: darkGrey),
                              prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Send Reset Email Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sendPasswordResetEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoading ? darkGrey : primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                                'Send Reset Email',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                        ),
                      ] else ...[
                        // Success State
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
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
                                'Check your email inbox and follow the instructions to reset your password.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Resend Email Button
                        TextButton.icon(
                          onPressed: _isLoading ? null : () {
                            setState(() => _emailSent = false);
                          },
                          icon: Icon(Icons.refresh, color: primaryColor),
                          label: Text(
                            'Resend Email',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      
                      // Back to Login Button
                      TextButton.icon(
                        onPressed: _isLoading ? null : () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        icon: Icon(Icons.arrow_back, color: darkGrey),
                        label: Text(
                          _emailSent ? 'Back to Login' : 'Remembered your password? Sign In',
                          style: TextStyle(
                            color: darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Help Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _emailSent 
                                  ? 'Didn\'t receive the email? Check your spam folder or try resending.'
                                  : 'Enter the email address associated with your account to receive reset instructions.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
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