import 'package:flutter/material.dart';

class Pallete {
  static const Color metalDark = Color(0xFF1A1D21);
  static const Color neonBlue = Color(0xFF00F7FF);

  // === 3D Button Colors ===

  // FACE: Thora Darker Silver (Kam White)
  static const LinearGradient metalFaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8E8E8), // Highlight
      Color(0xFFC0C0C0), // Silver
      Color(0xFFA0A0A0), // Darker Silver
    ],
  );

  // EDGE: Depth Color (Side walls of the 3D block)
  static const Color metalDepthColor = Color(0xFF404040); // Dark Greyish Black

  // === TextFields ===
  // Input fields ka background
  static const LinearGradient inputGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5F5F5), Color(0xFFD0D0D0)],
  );

  // === Shadows ===
  // Block Shadow (Jo zameen par girti hai)
  static List<BoxShadow> get blockShadows => [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      offset: const Offset(8, 8), // Shadow door gir rahi hai
      blurRadius: 10,
    ),
  ];
}
