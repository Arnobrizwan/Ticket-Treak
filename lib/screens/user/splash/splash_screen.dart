// lib/screens/user/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ticket_trek/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Violin color palette (consistent with other screens)
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
  static const Color textColor = Color(0xFF35281E); // Deep Wood
  static const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E); // Muted Brown

  late AnimationController _mainController;
  late AnimationController _loadingController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;

  bool _isInitialized = false;
  String _loadingMessage = 'Starting your journey...';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Loading animation controller
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Floating elements controller
    _floatingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
    ));

    // Slide animation for text
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    ));

    // Rotation animation for loading
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    ));

    // Bounce animation
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _mainController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Firebase
      setState(() {
        _loadingMessage = 'Initializing Firebase...';
        _loadingProgress = 0.2;
      });

      await Firebase.initializeApp();
      await FirebaseAnalytics.instance.logAppOpen();
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 2: Load app configuration
      setState(() {
        _loadingMessage = 'Loading configurations...';
        _loadingProgress = 0.4;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      // Step 3: Check student verification
      setState(() {
        _loadingMessage = 'Checking student benefits...';
        _loadingProgress = 0.6;
      });

      await Future.delayed(const Duration(milliseconds: 700));

      // Step 4: Loading travel data
      setState(() {
        _loadingMessage = 'Loading travel destinations...';
        _loadingProgress = 0.8;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      // Step 5: Finalizing
      setState(() {
        _loadingMessage = 'Ready for takeoff!';
        _loadingProgress = 1.0;
        _isInitialized = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text(
              'Connection Issue',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        content: const Text(
          'We couldn\'t start the app. Please check your internet connection and try again.',
          style: TextStyle(
            color: darkGrey,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _loadingMessage = 'Retrying...';
                _loadingProgress = 0.0;
              });
              _initializeApp();
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _loadingController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  backgroundColor,
                  subtleGrey.withOpacity(0.3),
                  primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // Dotted pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: DottedPatternPainter(
                color: primaryColor.withOpacity(0.05),
              ),
            ),
          ),

          // Floating elements
          _buildFloatingElements(),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated logo (single, merged design)
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildEnhancedLogo(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // App name and tagline
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: _buildBranding(),
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 1),

                  // Loading section
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildLoadingIndicator(),
                            const SizedBox(height: 24),
                            _buildStatusText(),
                            const SizedBox(height: 16),
                            _buildProgressBar(),
                          ],
                        ),
                      );
                    },
                  ),

                  const Spacer(flex: 2),

                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating paper plane
            Positioned(
              top: 120 + _bounceAnimation.value,
              right: 60,
              child: Transform.rotate(
                angle: 0.2,
                child: Icon(
                  Icons.send,
                  size: 24,
                  color: accentOrange.withOpacity(0.3),
                ),
              ),
            ),

            // Floating graduation cap
            Positioned(
              top: 200 - _bounceAnimation.value * 0.8,
              left: 40,
              child: Icon(
                Icons.school,
                size: 28,
                color: accentGreen.withOpacity(0.4),
              ),
            ),

            // Floating map pin
            Positioned(
              bottom: 250 + _bounceAnimation.value * 1.2,
              left: 80,
              child: Icon(
                Icons.location_on,
                size: 20,
                color: secondaryColor.withOpacity(0.3),
              ),
            ),

            // Floating luggage
            Positioned(
              bottom: 180 - _bounceAnimation.value * 0.6,
              right: 40,
              child: Icon(
                Icons.luggage,
                size: 22,
                color: primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: accentOrange.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle with gradient
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity(0.8),
                      subtleGrey.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Main content - integrated design without positioned elements
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top row with graduation cap
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentOrange, secondaryColor],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.school,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "30%",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Main airplane icon
                  Transform.rotate(
                    angle: -0.1,
                    child: const Icon(
                      Icons.flight_takeoff,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // App name with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              secondaryColor,
              accentOrange,
            ],
          ).createShader(bounds),
          child: const Text(
            'TicketTrek',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentOrange.withOpacity(0.9),
                accentGreen.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: accentOrange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.school,
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                'Student Flight Booking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Features text
        const Text(
          'Exclusive discounts • Budget-friendly • Easy booking',
          style: TextStyle(
            fontSize: 13,
            color: darkGrey,
            letterSpacing: 0.2,
          ),
        ),

        const SizedBox(height: 20),

        // Trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge('500K+', 'Students'),
            const SizedBox(width: 16),
            _buildTrustBadge('30%', 'Savings'),
            const SizedBox(width: 16),
            _buildTrustBadge('4.8★', 'Rating'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        primaryColor.withOpacity(0.3),
                        accentOrange,
                        accentGreen,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Center icon with pulse
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flight,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            _loadingMessage,
            key: ValueKey(_loadingMessage),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 220,
      height: 6,
      decoration: BoxDecoration(
        color: subtleGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 500),
        alignment: Alignment.centerLeft,
        child: Container(
          width: 220 * _loadingProgress,
          height: 6,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, accentOrange, accentGreen],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Social proof
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 14,
                  color: accentGreen,
                ),
                SizedBox(width: 6),
                Text(
                  'Trusted by universities worldwide',
                  style: TextStyle(
                    fontSize: 11,
                    color: darkGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Version info
          Text(
            'Version 1.2.0 • Made with ❤️ for students',
            style: TextStyle(
              fontSize: 10,
              color: darkGrey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Dotted pattern painter for background
class DottedPatternPainter extends CustomPainter {
  final Color color;
  DottedPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        if ((x + y) % 80 == 0) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
