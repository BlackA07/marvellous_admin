import 'package:flutter/material.dart';
import '../../theme/pallete.dart'; // Pallete import zaroori he

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Pallete.neonBlue, // Hamara theme color
        strokeWidth: 3,
      ),
    );
  }
}
