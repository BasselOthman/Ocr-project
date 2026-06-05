import 'package:flutter/material.dart';

class AppColors {
  // Lighter, more vibrant dark blues based on user feedback
  static const Color primary = Color(0xFF003366); // Rich but bright blue
  static const Color primaryDark = Color(0xFF001F3F);
  static const Color secondary = Color(0xFF0075FF); // Vibrant primary blue
  static const Color accent = Color(0xFF00D1FF); // Cyan/Teal accent
  
  static const Color background = Color(0xFF0F172A); // Slate dark background
  
  static const Color textLight = Color(0xFFF1F5F9); // Off-white for text
  static const Color textMuted = Color(0xFF94A3B8); // Muted grey for subtitles
  
  static const Color error = Color(0xFFFF4D4F);
  static const Color success = Color(0xFF00E676);

  // Helper gradients
  static const LinearGradient deepBlueGradient = LinearGradient(
    colors: [Color(0xFF003366), Color(0xFF00509E), Color(0xFF0075FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient meshGradient = LinearGradient(
    colors: [Color(0xFF00509E), Color(0xFF0075FF), Color(0xFF00D1FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
