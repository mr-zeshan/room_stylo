import 'package:flutter/material.dart';

abstract final class AppColors {
  // RoomStylo Brand Greens
  static const Color forest = Color(0xFF1E4D3A);
  static const Color forestDark = Color(0xFF12372B);
  static const Color forestLight = Color(0xFF3E7D5A);

  // RoomStylo Golds
  static const Color gold = Color(0xFFD4A253);
  static const Color goldDark = Color(0xFFB77A2D);
  static const Color goldLight = Color(0xFFE7C27E);

  // Background / Surface
  static const Color background = Color(0xFFF8F6EF);
  static const Color surface = Color(0xFFFFFDF8);
  static const Color surfaceSoft = Color(0xFFF2EEE4);

  // Text
  static const Color textPrimary = Color(0xFF202322);
  static const Color textSecondary = Color(0xFF6F726F);
  static const Color textLight = Color(0xFF9A9C98);

  // General
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color divider = Color(0xFFE5E1D8);
  static const Color error = Color(0xFFB3261E);

  // Primary RoomStylo Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      forestDark,
      forest,
      forestLight,
    ],
  );

  // Gold Accent Gradient
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      goldLight,
      gold,
      goldDark,
    ],
  );
}