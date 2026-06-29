import 'package:flutter/material.dart';

class AppColors {
  // Shared
  static const Color accent = Color(
    0xFF1877F2,
  ); // Facebook blue / Instagram blue hint
  static const Color secondary = Color(0xFF0095F6); // Instagram blue
  static const Color error = Color(0xFFFF4D4F);
  static const Color success = Color(0xFF00E676);

  // Light Mode
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF262626);
  static const Color lightTextMuted = Color(0xFF8E8E8E);
  static const Color lightDivider = Color(0xFFDBDBDB);

  // Dark Mode
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF121212);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextMuted = Color(0xFFA8A8A8);
  static const Color darkDivider = Color(0xFF363636);

  // Fallbacks for backward compatibility
  static const Color primary = accent;
  static const Color primaryDark = darkCard;
  static const Color background = darkBackground;
  static const Color textLight = darkText;
  static const Color textMuted = darkTextMuted;

  // Simple hint of blue gradient if needed somewhere
  static const LinearGradient meshGradient = LinearGradient(
    colors: [Color(0xFF1877F2), Color(0xFF0095F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient deepBlueGradient = meshGradient;
}
