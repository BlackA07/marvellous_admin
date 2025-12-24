import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pallete.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Pallete.metalDark, // Dark background
    primaryColor: Pallete.neonBlue,

    // Global Font: Comic Neue
    textTheme: GoogleFonts.comicNeueTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white),
  );
}
