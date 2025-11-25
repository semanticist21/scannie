import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// App spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Border radius constants
class AppRadius {
  AppRadius._();

  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0;
}

/// Shadow presets for consistent elevation
class AppShadows {
  AppShadows._();

  /// Subtle card shadow (8% black, 4px blur)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Dialog shadow (8% black, 20px blur)
  static const List<BoxShadow> dialog = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Subtle shadow for flat elements (10% black, 4px blur)
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Overlay badge shadow (60% black, 4px blur)
  static const List<BoxShadow> badge = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Darker overlay for text on images (50% black, 2px blur)
  static const List<BoxShadow> textOnImage = [
    BoxShadow(
      color: AppColors.overlay,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];
}

/// App theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // App bar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3,
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        color: AppColors.cardBackground,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTextStyles.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // WoltModalSheet theme extension
      extensions: const <ThemeExtension>[
        WoltModalSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBarrierColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          modalElevation: 8.0,
          topBarShadowColor: AppColors.shadowLight,
          dragHandleColor: AppColors.border,
          dragHandleSize: Size(40, 4),
          showDragHandle: true,
          enableDrag: true,
          useSafeArea: true,
          clipBehavior: Clip.antiAlias,
          mainContentScrollPhysics: ClampingScrollPhysics(),
        ),
      ],
    );
  }

  /// Background blur decorator for modals
  static Widget blurDecorator(Widget child) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: AppColors.barrier,
        child: child,
      ),
    );
  }

  /// Page content decorator with rounded corners for dialogs
  static Widget dialogContentDecorator(Widget child) {
    return Align(
      alignment: Alignment.center,
      child: child,
    );
  }

  /// Page content decorator for bottom sheets
  static Widget sheetContentDecorator(Widget child) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        child: child,
      ),
    );
  }
}
