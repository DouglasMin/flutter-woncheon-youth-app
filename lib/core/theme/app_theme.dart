import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — muted, reverent tone
  static const primary = Color(0xFF4A5568);
  static const primaryLight = Color(0xFF718096);
  static const primaryDark = Color(0xFF2D3748);

  // Accent — warm, subtle
  static const accent = Color(0xFFC9A96E);
  static const accentLight = Color(0xFFD4B88A);

  // Surface — warm gray base
  static const surface = Color(0xFFF5F5F3);
  static const surfaceCard = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF4A5568);
  static const textTertiary = Color(0xFFA0AEC0);
  static const textOnDark = Color(0xFFF7FAFC);
  static const textOnDarkSecondary = Color(0xFFCBD5E0);

  // Misc
  static const divider = Color(0xFFE2E8F0);
  static const error = Color(0xFFC53030);
  static const success = Color(0xFF2F855A);

  // Dark overlay
  static const darkOverlay = Color(0xFF1A202C);
}

abstract final class AppTheme {
  static const _pretendard = 'Pretendard';

  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _colorScheme,
        fontFamily: _pretendard,
        scaffoldBackgroundColor: AppColors.surface,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: _pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.primaryLight,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: _pretendard,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkOverlay,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      );

  static CupertinoThemeData get cupertino => const CupertinoThemeData(
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.surface,
        barBackgroundColor: Color(0xF0F5F5F3),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primaryDark,
        ),
      );
}
