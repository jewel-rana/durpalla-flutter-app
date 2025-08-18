import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart'; // or your main screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // Do any startup work here, then navigate
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ocean gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.oceanGradient,
            ),
          ),

          // (Optional) top curve image, if you’re using it elsewhere
          // Positioned(
          //   top: -40, left: 0, right: 0,
          //   child: IgnorePointer(
          //     child: Image.asset('assets/center-2.webp',
          //       height: 220, fit: BoxFit.cover, alignment: Alignment.topCenter),
          //   ),
          // ),

          // Centered logo
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Image.asset(
                'assets/logo-white.png', // (you attached this)
                width: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
