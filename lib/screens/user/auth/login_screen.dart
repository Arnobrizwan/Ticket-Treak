// File: lib/screens/user/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../routes/app_routes.dart';
import '../dashboard/home_dashboard.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ---------------------------------------------------------------------------
// A fully redesigned, enterprise-grade Login Screen for Flutter.
// Uses the “violin” color palette for consistency across the onboarding flow.
// ---------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // “Violin” palette (matching Onboarding & Registration)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor =
      Color(0xFF5C2E00); // Dark Brown (wood grain)
  static const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
  static const Color textColor = Color(0xFF35281E); // Deep Wood (almost black)
  static const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E); // Muted Brown

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade in effect for the form after a brief delay:
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isFormValid() {
    return _formKey.currentState?.validate() ?? false;
  }

  // ----------------------------------------------------------------------------
  // Method: _loginWithFirebase
  // Performs Email/Password login via Firebase Auth, updates Firestore, and
  // navigates to HomeDashboard upon success. Shows SnackBars for errors/success.
  // ----------------------------------------------------------------------------
  Future<void> _loginWithFirebase() async {
    if (!isFormValid()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign in with email and password:
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // 2. Update last login timestamp in Firestore:
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // 3. Retrieve user profile (for personalized greeting):
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        String userName = 'User';
        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          userName =
              userData['name'] ?? userCredential.user!.displayName ?? 'User';
        } else {
          userName = userCredential.user!.displayName ?? 'User';
        }

        if (mounted) {
          // Show success SnackBar:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _rememberMe
                    ? 'Welcome back, $userName! Login remembered.'
                    : 'Welcome back, $userName!',
              ),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Navigate to HomeDashboard:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDashboard(userName: userName),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Map error codes to friendly messages:
      String errorMessage = _getFirebaseErrorMessage(e.code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      // Catch-all error handling:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed: ${e.toString()}"),
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

  // ----------------------------------------------------------------------------
  // Method: _signInWithGoogle
  // Handles Google Sign‐In via GoogleSignIn & FirebaseAuth, creates/updates
  // Firestore profile if needed, and navigates to HomeDashboard. Provides SnackBars.
  // ----------------------------------------------------------------------------
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Trigger Google Sign‐In flow:
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User canceled the sign‐in:
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 2. Obtain GoogleAuth credentials:
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Authenticate with Firebase:
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // 4. Check / Create Firestore user profile:
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // New Google user – create profile:
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': userCredential.user!.displayName ?? 'User',
            'email': userCredential.user!.email ?? '',
            'phone': userCredential.user!.phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          // Existing user – update last login timestamp:
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }

        String userName = userCredential.user!.displayName ?? 'User';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome, $userName!'),
              backgroundColor: accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeDashboard(userName: userName),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Google sign-in failed: ${e.toString()}"),
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

  // ----------------------------------------------------------------------------
  // Helper: Map FirebaseAuthException codes → Friendly messages
  // ----------------------------------------------------------------------------
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  // ----------------------------------------------------------------------------
  // Build Method: Assembles the UI using a background image + gradient overlay,
  // and a central “frosted‐glass” Card for the form. Inputs use leading icons,
  // validation, and custom focus styling. Includes “Remember Me”, social sign‐in,
  // and navigation to “Register” / “Forgot Password” as per enterprise needs.
  // ----------------------------------------------------------------------------
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
          // Semi‐transparent gradient overlay (violin palette)
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                        child: const Icon(
                          Icons.flight_takeoff,
                          size: 48,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ─────────────────────────────────────────────────────
                      // Card containing the Login Form
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
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // ───────────────────────────────────────────────
                                // Title & Subtitle
                                // ───────────────────────────────────────────────
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sign in to continue your journey',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: darkGrey,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // ───────────────────────────────────────────────
                                // Email Field
                                // ───────────────────────────────────────────────
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.email_outlined,
                                        color: darkGrey),
                                    labelText: 'Email',
                                    labelStyle:
                                        const TextStyle(color: darkGrey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: subtleGrey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: subtleGrey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: primaryColor, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter Email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // ───────────────────────────────────────────────
                                // Password Field
                                // ───────────────────────────────────────────────
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.lock_outline,
                                        color: darkGrey),
                                    labelText: 'Password',
                                    labelStyle:
                                        const TextStyle(color: darkGrey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: subtleGrey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: subtleGrey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: primaryColor, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: Colors.red),
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
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter Password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // ───────────────────────────────────────────────
                                // Remember Me & Forgot Password
                                // ───────────────────────────────────────────────
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      "Remember Me",
                                      style:
                                          TextStyle(fontSize: 14, color: null),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context, AppRoutes.passwordReset),
                                      style: TextButton.styleFrom(
                                        foregroundColor: primaryColor,
                                      ),
                                      child: const Text(
                                        'Forgot password?',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // ───────────────────────────────────────────────
                                // Sign In Button
                                // ───────────────────────────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _loginWithFirebase,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // ───────────────────────────────────────────────
                                // Divider & “Or continue with”
                                // ───────────────────────────────────────────────
                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300),
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        "Or continue with",
                                        style: TextStyle(color: darkGrey),
                                      ),
                                    ),
                                    Expanded(
                                      child:
                                          Divider(color: Colors.grey.shade300),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // ───────────────────────────────────────────────
                                // Social Sign-In (Google & Apple)
                                // ───────────────────────────────────────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Google Sign-In
                                    GestureDetector(
                                      onTap:
                                          _isLoading ? null : _signInWithGoogle,
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.mail_outline,
                                          size: 26,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Apple Sign-In
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.apple,
                                        size: 26,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // ───────────────────────────────────────────────
                                // “Don’t have an account? Sign up” Link
                                // ───────────────────────────────────────────────
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => Navigator.pushReplacementNamed(
                                          context, AppRoutes.register),
                                  style: TextButton.styleFrom(
                                    foregroundColor: primaryColor,
                                  ),
                                  child: const Text(
                                    "Don't have an account? Sign Up",
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
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
