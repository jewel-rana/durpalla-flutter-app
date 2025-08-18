import 'package:flutter/material.dart';

class AppColors {
  // 🌊 Primary (Ocean Depth)
  static const Color deepNavyBlue = Color(0xFF003366); // trust, professionalism
  static const Color darkTeal     = Color(0xFF004F4F); // modern ocean feel

  // 🌊 Secondary (Waves & Accents)
  static const Color turquoise = Color(0xFF00C2CB); // fresh, vibrant
  static const Color aquaBlue  = Color(0xFF4FD1C5); // cool accent

  // 🌊 Backgrounds
  static const Color lightSeafoam = Color(0xFFE6FFFA);
  static const Color offWhite     = Color(0xFFF9FAFB);

  // 🌊 Common Gradients
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [deepNavyBlue, turquoise],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aquaGradient = LinearGradient(
    colors: [aquaBlue, lightSeafoam],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}