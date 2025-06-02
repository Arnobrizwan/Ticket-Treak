// lib/screens/user/onboarding/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Violin-inspired color palette
  static const Color backgroundColor = Color(0xFFF5F0E1); // Ivory
  static const Color primaryColor = Color(0xFF5C2E00); // Dark Brown
  static const Color secondaryColor = Color(0xFF8B5000); // Amber Brown
  static const Color textColor = Color(0xFF35281E); // Deep Wood (almost black)
  static const Color subtleGrey = Color(0xFFDAC1A7); // Light Tan
  static const Color darkGrey = Color(0xFF7E5E3C); // Medium Brown
  static const Color accentOrange = Color(0xFFD4A373); // Warm Highlight
  static const Color accentGreen = Color(0xFFB28F5E); // Muted Brown
  static const Color accentYellow = Color(0xFFE0C097); // Light Highlight

  final PageController _controller = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  final List<Map<String, dynamic>> onboardingData = [
    {
      'title': 'Save Big on Student Flights',
      'subtitle': 'Exclusive Malaysian Student Rates',
      'desc':
          'Get up to 30% off on flights with your student ID. Special rates on Malaysia Airlines, AirAsia, Batik Air & more for Malaysian students.',
      'icon': Icons.school,
      'secondaryIcon': Icons.savings,
      'highlight': '30% Student Discount',
      'color': accentOrange,
      'imageUrl':
          'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Petronas Towers
      'features': [
        'MyKad student verification',
        'Touch ’n Go payment',
        'Instant booking'
      ],
    },
    {
      'title': 'Explore Southeast Asia',
      'subtitle': 'ASEAN Student Network',
      'desc':
          'From KL to Bangkok, Singapore to Bali. Study trips, backpacking adventures, or quick getaways – all at student prices!',
      'icon': Icons.flight_takeoff,
      'secondaryIcon': Icons.public,
      'highlight': 'ASEAN Destinations',
      'color': secondaryColor,
      'imageUrl':
          'https://images.unsplash.com/photo-1508009603885-50cf7c579365?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Singapore skyline
      'features': [
        'KL • Singapore • Bangkok',
        'Bali • Hanoi • Manila',
        'Student group rates'
      ],
    },
    {
      'title': 'Smart Travel Companion',
      'subtitle': 'Made for Malaysian Students',
      'desc':
          'Split payments with classmates, track ringgit rates, get alerts for semester break deals. Your uni travel buddy!',
      'icon': Icons.phone_iphone,
      'secondaryIcon': Icons.group,
      'highlight': 'Travel Together',
      'color': accentGreen,
      'imageUrl':
          'https://images.unsplash.com/photo-1581683705068-ca8f49fc7f45?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80', // Langkawi beach
      'features': [
        'Split with GrabPay',
        'Uni group bookings',
        'Semester break deals'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();

    // Ensure status bar icons are dark on ivory background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Kick off initial animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onGetStarted();
    }
  }

  void _skipToEnd() {
    _onGetStarted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // ─────────────────────────────────────────────────────────────────────
          // Background Dotted Pattern
          // ─────────────────────────────────────────────────────────────────────
          Positioned.fill(
            child: Container(color: backgroundColor),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                color: primaryColor.withOpacity(0.02),
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────────────
          // Page Content
          // ─────────────────────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, _slideAnimation.value),
                              child: _buildOnboardingPage(onboardingData[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Header: Logo on left, “Skip” on right
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, secondaryColor]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.flight, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TicketTrek",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Malaysian Students",
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Skip Button
          TextButton(
            onPressed: _skipToEnd,
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              children: const [
                Text(
                  'Skip',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Single Onboarding Page
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOnboardingPage(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // “Popular Routes” container only on page index 1
          if (_currentPage == 1)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: subtleGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Popular Student Routes",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildRouteChip("KL ↔ Penang"),
                      _buildRouteChip("JB ↔ KL"),
                      _buildRouteChip("KL ↔ Langkawi"),
                      _buildRouteChip("KL ↔ Singapore"),
                      _buildRouteChip("KL ↔ Bangkok"),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Animated Highlight Badge
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (data['color'] as Color).withOpacity(0.8),
                        data['color'] as Color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: (data['color'] as Color).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data['secondaryIcon'] as IconData,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['highlight'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // IMAGE CARD: full width, 280 height
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: data['imageUrl'] as String,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 280,
                placeholder: (context, url) => Container(
                  color: subtleGrey,
                  child:
                      const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: subtleGrey,
                  child: Icon(
                    data['icon'] as IconData,
                    size: 80,
                    color: darkGrey,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            data['title'] as String,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Subtitle with light tinted background
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: (data['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              data['subtitle'] as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: (data['color'] as Color),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            data['desc'] as String,
            style: TextStyle(
              fontSize: 14,
              color: darkGrey,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRouteChip(String route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Text(
        route,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryColor,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Section: Page Indicators, Progress Bar, Navigation Buttons
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              onboardingData.length,
              (index) {
                final bool isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 32 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (onboardingData[_currentPage]['color'] as Color)
                        : subtleGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Progress bar
          Stack(
            children: [
              Container(
                height: 4,
                width: 200,
                decoration: BoxDecoration(
                  color: subtleGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                width:
                    200 * ((_currentPage + 1) / onboardingData.length),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      onboardingData[_currentPage]['color'] as Color,
                      (onboardingData[_currentPage]['color']
                              as Color)
                          .withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Navigation buttons (Back / Continue)
          Row(
            children: [
              if (_currentPage > 0) ...[
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: darkGrey,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: _currentPage == 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        onboardingData[_currentPage]['color']
                            as Color,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == onboardingData.length - 1
                            ? 'Start Saving'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == onboardingData.length - 1
                            ? Icons.rocket_launch
                            : Icons.arrow_forward,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // “Trusted by…” text only on last page
          if (_currentPage == onboardingData.length - 1)
            Text(
              '🇲🇾 Trusted by 200,000+ Malaysian students',
              style: TextStyle(
                fontSize: 13,
                color: darkGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom painter for the dotted background pattern
// -----------------------------------------------------------------------------
class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw dotted pattern every 30 px
    for (double x = 0; x < size.width; x += 30) {
      for (double y = 0; y < size.height; y += 30) {
        if ((x + y) % 60 == 0) {
          canvas.drawCircle(Offset(x, y), 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}