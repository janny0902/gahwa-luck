import 'package:flutter/material.dart';

/// 기획: 베이지 베이스 + 포인트 紅 / 黃 / 黑
class AppColors {
  static const beige = Color(0xFFF3E6D4);
  static const beigeDeep = Color(0xFFE8D4B8);
  static const crimson = Color(0xFFB43A3A);
  static const gold = Color(0xFFC9A227);
  static const ink = Color(0xFF1A1A1A);
  static const inkSoft = Color(0xFF4A4036);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      // 모든 화면은 HanjiBackground 위에 그린다.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.light(
        primary: AppColors.crimson,
        secondary: AppColors.gold,
        surface: AppColors.beige,
        onPrimary: Colors.white,
        onSecondary: AppColors.ink,
        onSurface: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.inkSoft,
        displayColor: AppColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFF8EE).withValues(alpha: 0.7),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
