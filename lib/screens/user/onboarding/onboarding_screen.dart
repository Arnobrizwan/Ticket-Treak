import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // Enterprise color palette from dashboard
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color primaryColor = Color(0xFF3F3D9A);
  static const Color secondaryColor = Color(0xFF6C63FF);
  static const Color textColor = Color(0xFF2D3142);
  static const Color subtleGrey = Color(0xFFEBEEF2);
  static const Color darkGrey = Color(0xFF8F96A3);

  final PageController _controller = PageController();
  int _currentPage = 0;
  
  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Enterprise Flight Management',
      'subtitle': 'Professional Travel Solutions',
      'desc': 'Streamline your business travel with our comprehensive flight booking and management platform designed for modern enterprises.',
      'icon': 'flight_takeoff',
      'highlight': 'Discover & Book',
    },
    {
      'title': 'Trusted Airline Partners',
      'subtitle': 'Premium Business Travel',
      'desc': 'Partner with Malaysia Airlines, Batik Air, AirAsia, and other premium carriers for reliable business travel solutions.',
      'icon': 'business',
      'highlight': 'Enterprise Grade',
    },
    {
      'title': 'Complete Travel Control',
      'subtitle': 'Seamless Management',
      'desc': 'Manage bookings, track expenses, ensure policy compliance, and handle refunds through our integrated business platform.',
      'icon': 'dashboard',
      'highlight': 'Full Control',
    },
  ];

  void _onGetStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip and progress
            _buildHeader(),
            
            // Main content
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(onboardingData[index], screenSize);
                },
              ),
            ),
            
            // Bottom section with indicators and buttons
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Company logo and name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flight,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "TicketTrek",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          
          // Skip button
          TextButton(
            onPressed: _skipToEnd,
            style: TextButton.styleFrom(
              foregroundColor: darkGrey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> data, Size screenSize) {
    IconData iconData;
    switch (data['icon']) {
      case 'flight_takeoff':
        iconData = Icons.flight_takeoff;
        break;
      case 'business':
        iconData = Icons.business;
        break;
      case 'dashboard':
        iconData = Icons.dashboard;
        break;
      default:
        iconData = Icons.flight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Highlight badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: secondaryColor.withOpacity(0.3)),
            ),
            child: Text(
              data['highlight']!,
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Main icon with background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              iconData,
              color: primaryColor,
              size: 48,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            data['title']!,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Subtitle
          Text(
            data['subtitle']!,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            data['desc']!,
            style: TextStyle(
              fontSize: 16,
              color: darkGrey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
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
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 32 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? primaryColor : subtleGrey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Progress text
          Text(
            '${_currentPage + 1} of ${onboardingData.length}',
            style: TextStyle(
              fontSize: 14,
              color: darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              
              if (_currentPage > 0) const SizedBox(width: 16),
              
              Expanded(
                flex: _currentPage == 0 ? 1 : 2,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == onboardingData.length - 1 
                            ? 'Get Started' 
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_currentPage < onboardingData.length - 1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}