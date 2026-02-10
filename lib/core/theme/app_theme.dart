import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // Blue primary
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
