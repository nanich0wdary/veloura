import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFC084FC),
      secondary: Color(0xFFF472B6),
    ),
    textTheme: TextTheme(
      bodyMedium: GoogleFonts.cormorantGaramond(),
      titleMedium: GoogleFonts.cinzel(),
    ),
  );
}
