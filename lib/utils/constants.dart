// lib/utils/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme
  static const lightPrimary = Color(0xFF1E1E1E);
  static const lightSecondary = Color(0xFF424242);
  static const lightAccent = Color(0xFFFF6B6B);

  // Dark Theme
  static const darkPrimary = Color(0xFF121212);
  static const darkSecondary = Color(0xFF2C2C2C);
  static const darkAccent = Color(0xFF4ECDC4);

  // Button colors
  static const numberBtnLight = Color(0xFFF5F5F5);
  static const operatorBtnLight = Color(0xFFFFE0E0);
  static const specialBtnLight = Color(0xFFE0E0E0);
  static const equalsBtnLight = Color(0xFFFF6B6B);

  static const numberBtnDark = Color(0xFF2C2C2C);
  static const operatorBtnDark = Color(0xFF3D2C2C);
  static const specialBtnDark = Color(0xFF1E1E1E);
  static const equalsBtnDark = Color(0xFF4ECDC4);
}

class AppTextStyles {
  static const displayStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 32,
    fontWeight: FontWeight.w500,
  );

  static const expressionStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w300,
  );

  static const historyStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w300,
  );

  static const buttonStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
}

class AppDimensions {
  static const buttonSpacing = 12.0;
  static const buttonRadius = 16.0;
  static const displayRadius = 24.0;
  static const screenPadding = 24.0;
  static const buttonPressAnimDuration = Duration(milliseconds: 200);
  static const modeSwitchAnimDuration = Duration(milliseconds: 300);
}

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF0F0F0),
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightAccent,
    surface: Colors.white,
  ),
  fontFamily: 'Roboto',
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkPrimary,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkSecondary,
    secondary: AppColors.darkAccent,
    surface: AppColors.darkSecondary,
  ),
  fontFamily: 'Roboto',
);
