import 'package:flutter/material.dart';

/// Scannie 앱의 테마 관리 클래스
/// Material 3 디자인 시스템 기반
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ============================================================================
  // 시드 컬러 (ColorScheme.fromSeed의 기준)
  // ============================================================================

  static const Color _primarySeedColor = Color(0xFF2196F3); // Material Blue
  static const Color _tertiarySeedColor = Color(0xFFFFA726); // Amber for Premium

  // ============================================================================
  // 커스텀 컬러 (ColorScheme에 없는 특수 용도)
  // ============================================================================

  /// 카메라/편집 화면 배경색 (완전한 검은색)
  static const Color cameraDarkBackground = Color(0xFF000000);

  /// 성공/정렬 완료 색상
  static const Color success = Color(0xFF4CAF50);

  /// 할인/프로모션 뱃지 색상
  static const Color promotion = Color(0xFFFF9800);

  // ============================================================================
  // Light Theme
  // ============================================================================

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.light,
      // Tertiary는 프리미엄 기능에 사용
      tertiary: _tertiarySeedColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // AppBar 테마
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // Elevated Button 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),

      // Floating Action Button 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),

      // Card 테마
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Input Decoration 테마
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),

      // BottomNavigationBar 테마
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
    );
  }

  // ============================================================================
  // Dark Theme
  // ============================================================================

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.dark,
      tertiary: _tertiarySeedColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ============================================================================
// Theme Extension Helper
// ============================================================================

/// BuildContext에서 쉽게 테마에 접근하기 위한 확장
extension ThemeExtension on BuildContext {
  /// ColorScheme 빠른 접근
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// TextTheme 빠른 접근
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 커스텀 컬러 접근
  Color get cameraDarkBg => AppTheme.cameraDarkBackground;
  Color get successColor => AppTheme.success;
  Color get promotionColor => AppTheme.promotion;
}
