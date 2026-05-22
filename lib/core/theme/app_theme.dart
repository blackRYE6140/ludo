import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const Color primary = Color(0xFFC5412D);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF1E9D2),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFAF7EC),
        foregroundColor: Color(0xFF2D2A26),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFFFEFDF8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0D8C2)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
