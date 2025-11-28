import 'package:flutter/material.dart';

/// App color palette following Material Design principles
/// All colors should be accessed through this class - never use Colors.xxx directly
class AppColors {
  AppColors._();

  // ============================================
  // Primary colors - Clean and professional blue
  // ============================================
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);

  // ============================================
  // Accent colors
  // ============================================
  static const Color accent = Color(0xFF00BCD4);
  static const Color accentDark = Color(0xFF0097A7);

  // ============================================
  // Base colors (replacing Colors.xxx usage)
  // ============================================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Grey scale (replacing Colors.grey.shadeXXX)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ============================================
  // Neutral colors - Shadcn Slate
  // ============================================
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ============================================
  // Text colors
  // ============================================
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ============================================
  // Status colors
  // ============================================
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);

  // ============================================
  // Border and divider
  // ============================================
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ============================================
  // Overlay colors
  // ============================================
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color shimmer = Color(0xFFE0E0E0);

  // ============================================
  // Neumorphic colors
  // ============================================
  static const Color neumorphicBase = Color(0xFFE0E5EC);
  static const Color neumorphicShadowDark = Color(0xFF8E9AAF);

  // ============================================
  // Shadow colors (for BoxShadow)
  // ============================================
  static const Color shadowLight = Color(0x14000000); // 8% black
  static const Color shadowMedium = Color(0x1A000000); // 10% black
  static const Color shadowDark = Color(0x99000000); // 60% black
  static const Color shadowDarker = Color(0xB3000000); // 70% black
  static const Color shadowDarkest = Color(0xCC000000); // 80% black

  // ============================================
  // Barrier/Scrim colors
  // ============================================
  static const Color barrier = Color(0x66000000); // 40% black
  static const Color barrierDark = Color(0xB3000000); // 70% black

  // ============================================
  // Dark mode colors (for full screen viewers)
  // ============================================
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF121212);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF); // white70
  static const Color darkTextTertiary = Color(0x8AFFFFFF); // white54
  static const Color darkOverlay = Color(0x33FFFFFF); // white20
  static const Color darkOverlayLight = Color(0x80FFFFFF); // white50

  // ============================================
  // Semantic color aliases for common use cases
  // ============================================
  /// Use for icon buttons on dark backgrounds
  static const Color iconOnDark = white;
  /// Use for icon buttons on light backgrounds
  static const Color iconOnLight = textPrimary;
  /// Use for disabled states
  static const Color disabled = grey400;
  /// Use for hover states on light buttons
  static const Color hoverLight = grey200;
  /// Use for pressed states on light buttons
  static const Color pressedLight = grey300;
}
