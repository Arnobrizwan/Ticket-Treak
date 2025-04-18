import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Discover and Book Flights',
      'desc': 'Browse beautiful destinations and book flights in minutes.',
      'image': 'https://cdn-icons-png.flaticon.com/512/201/201623.png',
      'logo': '',
    },
    {
      'title': 'Trusted Airline Partners',
      'desc': 'Fly with Malaysia Airlines, Batik Air, and AirAsia.',
      'image': 'https://cdn-icons-png.flaticon.com/512/3163/3163090.png',
      'logo': 'https://i.imgur.com/Q9KZ6pO.png',
    },
    {
      'title': 'Enjoy a Smooth Journey',
      'desc': 'Manage your bookings, seats, and refunds with ease.',
      'image': 'https://cdn-icons-png.flaticon.com/512/1146/1146869.png',
      'logo': '',
    },
  ];

  void _onGetStarted() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40), // spacing from top
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
                  final item = onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(item['image']!, height: 200),
                        if (item['logo']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Image.network(item['logo']!, height: 60),
                          ),
                        const SizedBox(height: 30),
                        Text(
                          item['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['desc']!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.indigo : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: ElevatedButton(
                onPressed: _onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}