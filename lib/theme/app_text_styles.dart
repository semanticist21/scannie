import 'package:flutter/material.dart';
import 'app_colors.dart';

// ============================================
// Font Size Tokens
// ============================================
/// Font size constants for consistent typography
/// Use these instead of hardcoded numeric fontSize values
class AppFontSize {
  AppFontSize._();

  /// 9px - Extra extra small (badges, counts)
  static const double xxs = 9.0;
  /// 10px - Extra small (overline, micro text)
  static const double xs = 10.0;
  /// 12px - Small (caption, helper text)
  static const double sm = 12.0;
  /// 13px - Small-medium (compact labels)
  static const double smd = 13.0;
  /// 14px - Medium (body, labels)
  static const double md = 14.0;
  /// 16px - Large (body large, buttons)
  static const double lg = 16.0;
  /// 20px - Extra large (h3, section titles)
  static const double xl = 20.0;
  /// 24px - 2x large (h2, page titles)
  static const double xxl = 24.0;
  /// 32px - 3x large (h1, hero text)
  static const double xxxl = 32.0;
}

// ============================================
// Font Weight Tokens
// ============================================
/// Font weight constants for consistent typography
/// Use these instead of FontWeight.wXXX directly
class AppFontWeight {
  AppFontWeight._();

  /// Normal text (400)
  static const FontWeight normal = FontWeight.w400;
  /// Medium emphasis (500) - labels, list items
  static const FontWeight medium = FontWeight.w500;
  /// Semi-bold (600) - buttons, subtitles
  static const FontWeight semiBold = FontWeight.w600;
  /// Bold (700) - headings
  static const FontWeight bold = FontWeight.w700;
}

// ============================================
// Typography System
// ============================================
/// Typography system following Material Design guidelines
class AppTextStyles {
  AppTextStyles._();

  // ============================================
  // Headline styles
  // ============================================
  static const TextStyle h1 = TextStyle(
    fontSize: AppFontSize.xxxl,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: AppFontSize.xxl,
    fontWeight: AppFontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: AppFontSize.xl,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );

  // ============================================
  // Body text styles
  // ============================================
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: AppFontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: AppFontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppFontSize.sm,
    fontWeight: AppFontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ============================================
  // Button text
  // ============================================
  static const TextStyle button = TextStyle(
    fontSize: AppFontSize.lg,
    fontWeight: AppFontWeight.semiBold,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: AppFontWeight.semiBold,
    letterSpacing: 0.5,
  );

  // ============================================
  // Caption and labels
  // ============================================
  static const TextStyle caption = TextStyle(
    fontSize: AppFontSize.sm,
    fontWeight: AppFontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: AppFontWeight.medium,
    color: AppColors.textPrimary,
  );

  /// Label with semi-bold weight (for section headers)
  static const TextStyle labelSemiBold = TextStyle(
    fontSize: AppFontSize.md,
    fontWeight: AppFontWeight.semiBold,
    color: AppColors.textPrimary,
  );

  // ============================================
  // Extra small text
  // ============================================
  static const TextStyle overline = TextStyle(
    fontSize: AppFontSize.xs,
    fontWeight: AppFontWeight.medium,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  /// Extra extra small text (badges, page counts)
  static const TextStyle micro = TextStyle(
    fontSize: AppFontSize.xxs,
    fontWeight: AppFontWeight.medium,
    color: AppColors.textSecondary,
  );

  /// Compact label (13px)
  static const TextStyle labelCompact = TextStyle(
    fontSize: AppFontSize.smd,
    fontWeight: AppFontWeight.normal,
    color: AppColors.textPrimary,
  );
}
