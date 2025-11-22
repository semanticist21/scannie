import 'package:flutter/material.dart';

/// App color palette following Material Design principles
class AppColors {
  AppColors._();

  // Primary colors - Clean and professional blue
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // Accent colors
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF0097A7);

  // Neutral colors - Shadcn Slate
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // Border and divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Overlay colors
  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFFE0E0E0);
}
