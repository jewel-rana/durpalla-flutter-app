// top_wave_background.dart
import 'package:flutter/material.dart';

class TopWaveBackground extends StatelessWidget {
  final double height;
  final Widget child;
  const TopWaveBackground({
    super.key,
    required this.child,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base page color (optional)
        Positioned.fill(child: Container(color: const Color(0xFFF9FAFB))),
        // The gradient wave image
        Positioned(
          top: -40, // pull a bit up so the curve sits nicer
          left: 0,
          right: 0,
          child: IgnorePointer( // don’t block touches
            child: Image.asset(
              'assets/center-2.webp',  // put your file in assets/
              height: height,
              fit: BoxFit.cover,       // stretch nicely across width
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        // Your page content
        Padding(
          padding: EdgeInsets.only(top: height - 40), // keep content below the wave
          child: child,
        ),
      ],
    );
  }
}
