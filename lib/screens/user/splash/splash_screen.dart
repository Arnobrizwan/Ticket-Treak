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
  // Youthful color palette for students
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF2D3142);
  static const Color darkGrey = Color(0xFF8F96A3);
  static const Color accentOrange = Color(0xFFFF6B6B);
  static const Color accentGreen = Color(0xFF4ECDC4);
  static const Color lightGrey = Color(0xFFE8EBEF);

  late AnimationController _mainController;
  late AnimationController _loadingController;
  late AnimationController _floatingController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _bounceAnimation;

  bool _isInitialized = false;
  String _loadingMessage = 'Starting your adventure...';

  // Unsplash images for student travel theme
  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=1600&q=80', // Travel planning
    'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=1600&q=80', // Airplane wing
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=1600&q=80', // Student travelers
  ];

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
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Floating elements controller
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
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
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
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
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _mainController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _loadingMessage = 'Initializing Firebase...';
      });
      
      // Initialize Firebase
      await Firebase.initializeApp();
      await FirebaseAnalytics.instance.logAppOpen();
      
      setState(() {
        _loadingMessage = 'Loading travel data...';
      });
      
      // Simulate loading user preferences and data
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _loadingMessage = 'Checking student discounts...';
      });
      
      await Future.delayed(const Duration(milliseconds: 600));
      
      setState(() {
        _loadingMessage = 'Ready to explore!';
        _isInitialized = true;
      });
      
      // Wait for a smooth transition
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    } catch (e) {
      // Handle initialization errors
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: accentOrange),
            const SizedBox(width: 8),
            const Text('Oops!'),
          ],
        ),
        content: const Text(
          'We couldn\'t start the app. Please check your internet connection and try again.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _loadingMessage = 'Retrying...';
              });
              _initializeApp();
            },
            child: const Text('Retry'),
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
          // Background image with overlay
          _buildBackgroundImage(),
          
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                  primaryColor.withOpacity(0.8),
                ],
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
                  
                  // Animated logo
                  AnimatedBuilder(
                    animation: _mainController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: _buildLogo(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
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
                            const SizedBox(height: 20),
                            _buildStatusText(),
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

  Widget _buildBackgroundImage() {
    return CachedNetworkImage(
      imageUrl: _backgroundImages[1], // Using airplane wing image
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: backgroundColor,
      ),
      errorWidget: (context, url, error) => Container(
        color: backgroundColor,
        child: const Icon(
          Icons.flight,
          size: 100,
          color: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating clouds
            Positioned(
              top: 100 + _bounceAnimation.value,
              left: 50,
              child: Opacity(
                opacity: 0.3,
                child: Icon(
                  Icons.cloud,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            
            Positioned(
              top: 200 - _bounceAnimation.value,
              right: 30,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.cloud,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Floating plane
            Positioned(
              bottom: 300 + _bounceAnimation.value * 2,
              right: 50,
              child: Transform.rotate(
                angle: 0.1,
                child: Opacity(
                  opacity: 0.4,
                  child: Icon(
                    Icons.flight,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient background
            Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.1),
                    secondaryColor.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            
            // Icon composition
            Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        secondaryColor.withOpacity(0.2),
                        primaryColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
                
                // Main plane icon
                Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 50,
                    color: primaryColor,
                  ),
                ),
                
                // Student cap overlay
                Positioned(
                  top: 20,
                  right: 25,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        // App name
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.9)],
          ).createShader(bounds),
          child: const Text(
            'TicketTrek',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1.2,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentOrange.withOpacity(0.8),
                accentGreen.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: accentOrange.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Student Flight Booking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Features text
        const Text(
          'Exclusive discounts • Budget-friendly • Easy booking',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
            letterSpacing: 0.3,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Trust badges
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustBadge('500K+', 'Students'),
            const SizedBox(width: 20),
            _buildTrustBadge('30%', 'Savings'),
            const SizedBox(width: 20),
            _buildTrustBadge('4.8', 'Rating'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
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
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        accentOrange.withOpacity(0.3),
                        accentOrange,
                        accentGreen,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Center icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flight,
                  size: 24,
                  color: primaryColor,
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
          duration: const Duration(milliseconds: 500),
          child: Text(
            _loadingMessage,
            key: ValueKey(_loadingMessage),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Progress bar
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            alignment: Alignment.centerLeft,
            child: Container(
              width: _isInitialized ? 200 : 100,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentOrange, accentGreen],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Social proof
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: accentGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trusted by universities worldwide',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Version info
          Text(
            'Version 1.2.0 • Made with ❤️ for students',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}