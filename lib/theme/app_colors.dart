import 'package:flutter/material.dart';

/// App color palette following Material Design principles
/// All colors should be accessed through this class - never use Colors.xxx directly
///
/// This class provides both static light mode colors and a dynamic [of] method
/// that returns theme-appropriate colors based on the current brightness.
class AppColors {
  AppColors._();

  // ============================================
  // Tailwind CSS Slate Palette (for reference)
  // ============================================
  // slate-50:  #F8FAFC
  // slate-100: #F1F5F9
  // slate-200: #E2E8F0
  // slate-300: #CBD5E1
  // slate-400: #94A3B8
  // slate-500: #64748B
  // slate-600: #475569
  // slate-700: #334155
  // slate-800: #1E293B
  // slate-900: #0F172A
  // slate-950: #020617

  // ============================================
  // Primary colors - Teal (matching app icon theme)
  // Tailwind CSS Teal palette: 400=#2dd4bf, 500=#14b8a6, 600=#0d9488, 700=#0f766e
  // ============================================
  static const Color primary = Color(0xFF0d9488);       // teal-600
  static const Color primaryDark = Color(0xFF0f766e);   // teal-700
  static const Color primaryLight = Color(0xFF99f6e4);  // teal-200

  // ============================================
  // Accent colors - Teal variants
  // ============================================
  static const Color accent = Color(0xFF14b8a6);        // teal-500
  static const Color accentDark = Color(0xFF0d9488);    // teal-600

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

  // Slate scale (Tailwind CSS)
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ============================================
  // Light Mode - Neutral colors (Shadcn Slate)
  // ============================================
  static const Color background = Color(0xFFF8FAFC);     // slate-50
  static const Color surface = Color(0xFFFFFFFF);         // white
  static const Color cardBackground = Color(0xFFFFFFFF);  // white

  // ============================================
  // Light Mode - Text colors
  // ============================================
  static const Color textPrimary = Color(0xFF0F172A);     // slate-900
  static const Color textSecondary = Color(0xFF64748B);   // slate-500
  static const Color textHint = Color(0xFF94A3B8);        // slate-400

  // ============================================
  // Light Mode - Status colors
  // ============================================
  static const Color success = Color(0xFF22C55E);         // green-500
  static const Color warning = Color(0xFFF59E0B);         // amber-500
  static const Color error = Color(0xFFEF4444);           // red-500

  // ============================================
  // Light Mode - Border and divider
  // ============================================
  static const Color border = Color(0xFFE2E8F0);          // slate-200
  static const Color divider = Color(0xFFF1F5F9);         // slate-100

  // ============================================
  // Dark Mode - Neutral colors
  // ============================================
  static const Color backgroundDark = Color(0xFF0F172A);  // slate-900
  static const Color surfaceDark = Color(0xFF1E293B);     // slate-800
  static const Color cardBackgroundDark = Color(0xFF1E293B); // slate-800

  // ============================================
  // Dark Mode - Text colors
  // ============================================
  static const Color textPrimaryDark = Color(0xFFF8FAFC);   // slate-50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // slate-400
  static const Color textHintDark = Color(0xFF64748B);      // slate-500

  // ============================================
  // Dark Mode - Status colors (slightly brighter for visibility)
  // ============================================
  static const Color successDark = Color(0xFF4ADE80);       // green-400
  static const Color warningDark = Color(0xFFFBBF24);       // amber-400
  static const Color errorDark = Color(0xFFF87171);         // red-400

  // ============================================
  // Dark Mode - Border and divider
  // ============================================
  static const Color borderDark = Color(0xFF334155);        // slate-700
  static const Color dividerDark = Color(0xFF1E293B);       // slate-800

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

/// Theme-aware color accessor
/// Use this to get colors that adapt to the current theme
class ThemedColors {
  final bool isDark;

  const ThemedColors._(this.isDark);

  /// Create from BuildContext
  factory ThemedColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ThemedColors._(brightness == Brightness.dark);
  }

  /// Create for specific brightness
  factory ThemedColors.forBrightness(Brightness brightness) {
    return ThemedColors._(brightness == Brightness.dark);
  }

  // Background colors
  Color get background => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get surface => isDark ? AppColors.surfaceDark : AppColors.surface;
  Color get cardBackground => isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground;

  // Text colors
  Color get textPrimary => isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textHint => isDark ? AppColors.textHintDark : AppColors.textHint;

  // Status colors
  Color get success => isDark ? AppColors.successDark : AppColors.success;
  Color get warning => isDark ? AppColors.warningDark : AppColors.warning;
  Color get error => isDark ? AppColors.errorDark : AppColors.error;

  // Border and divider
  Color get border => isDark ? AppColors.borderDark : AppColors.border;
  Color get divider => isDark ? AppColors.dividerDark : AppColors.divider;

  // Shimmer
  Color get shimmer => isDark ? AppColors.slate700 : AppColors.shimmer;

  // Icon colors
  Color get icon => textPrimary;
  Color get iconSecondary => textSecondary;
}
