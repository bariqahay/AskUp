import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Colors.grey[50],
    
    colorScheme: ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Colors.white,
      background: Colors.grey[50]!,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onBackground: Colors.black,
      onError: Colors.white,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
  
  // Dark Theme
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: Color(0xFF121212),
    
    colorScheme: ColorScheme.dark(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      surface: Color(0xFF1E1E1E),
      background: Color(0xFF121212),
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    
    cardTheme: CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
