import 'package:flutter/material.dart';

class AppTheme {
  // Light theme colors
  static final ColorScheme lightColorScheme = ColorScheme.light(
    primary: Color(0xFF6750A4),
    onPrimary: Colors.white,
    secondary: Color(0xFF625B71),
    onSecondary: Colors.white,
    surface: Colors.white,
    background: Color(0xFFFFFBFE),
    error: Color(0xFFB3261E),
  );

  // Dark theme colors
  static final ColorScheme darkColorScheme = ColorScheme.dark(
    primary: Color(0xFFD0BCFF),
    onPrimary: Color(0xFF381E72),
    secondary: Color(0xFFCCC2DC),
    onSecondary: Color(0xFF332D41),
    surface: Color(0xFF1C1B1F),
    background: Color(0xFF1C1B1F),
    error: Color(0xFFF2B8B5),
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}