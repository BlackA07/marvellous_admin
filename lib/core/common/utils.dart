import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// SnackBar dikhane ka function
void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.comicNeue(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.redAccent, // Error/Info color
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
}

// Future: Yahan hum 'pickImage()' function bhi add karenge jab 'file_picker' package add hoga.
