import 'package:flutter/material.dart';

/// Production-grade color palette for Earn++ app.
/// Uses modern, accessible colors with proper contrast ratios.
class AppColors {
  // Primary gradient colors
  static const Color primaryGradientStart = Color(0xFF667EEA);
  static const Color primaryGradientEnd = Color(0xFF764BA2);

  // Secondary colors
  static const Color secondaryLight = Color(0xFFF093FB);
  static const Color secondaryDark = Color(0xFF4158D0);

  // Accent colors
  static const Color accentGreen = Color(0xFF00D4AA);
  static const Color accentOrange = Color(0xFFFF6B6B);
  static const Color accentYellow = Color(0xFFFFD93D);

  // Neutral colors
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2D2D2D);

  // Text colors
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF757575);
  static const Color textMutedLight = Color(0xFFBDBDBD);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Shadow colors
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [secondaryLight, secondaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, accentOrange],
  );

  // Success to Warning gradient
  static const LinearGradient successWarningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, warning],
  );
}
