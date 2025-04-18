// lib/screens/user/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:ticket_trek/routes/app_routes.dart';

enum SplashLoaderStyle { spinner, fadeScale, lottie }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 💡 Change this to try different loaders
  final SplashLoaderStyle loaderStyle = SplashLoaderStyle.fadeScale;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0FE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loaderStyle == SplashLoaderStyle.spinner)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              )
            else if (loaderStyle == SplashLoaderStyle.fadeScale)
              TweenAnimationBuilder(
                duration: const Duration(seconds: 2),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: const Icon(Icons.flight_takeoff,
                          size: 64, color: Colors.indigo),
                    ),
                  );
                },
              )
            else if (loaderStyle == SplashLoaderStyle.lottie)
              Lottie.asset(
                'assets/plane_loader.json',
                width: 150,
                height: 150,
              ),
            const SizedBox(height: 16),
            const Text(
              'TicketTrek',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }
}