import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF6C63FF),
      scaffoldBackgroundColor: const Color(0xFFF7F6FB),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}