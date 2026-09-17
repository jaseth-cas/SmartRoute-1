import 'package:flutter/material.dart';
import 'colors.dart';

class SmartTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: SmartColors.smartBlue,
        secondary: SmartColors.smartLightBlue,
        tertiary: SmartColors.smartGreen,
        surface: SmartColors.smartBackground,
        onPrimary: Colors.white,
        onSecondary: SmartColors.smartText,
        onTertiary: Colors.white,
        onSurface: SmartColors.smartText,
      ),
      scaffoldBackgroundColor: SmartColors.smartBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: SmartColors.smartBlue,
        elevation: 1,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartColors.smartBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        color: SmartColors.smartSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SmartColors.smartBorder, width: 1),
        ),
      ),
    );
  }
}
