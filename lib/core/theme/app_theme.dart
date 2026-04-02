import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Light Mode ──
  static const primary = Color(0xFF4A5568);
  static const primaryLight = Color(0xFF718096);
  static const primaryDark = Color(0xFF2D3748);

  static const accent = Color(0xFFC9A96E);
  static const accentLight = Color(0xFFD4B88A);

  static const surface = Color(0xFFF5F5F3);
  static const surfaceCard = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF4A5568);
  static const textTertiary = Color(0xFFA0AEC0);
  static const textOnDark = Color(0xFFF7FAFC);
  static const textOnDarkSecondary = Color(0xFFCBD5E0);

  static const divider = Color(0xFFE2E8F0);
  static const error = Color(0xFFC53030);
  static const success = Color(0xFF2F855A);
  static const darkOverlay = Color(0xFF1A202C);

  // ── Dark Mode ──
  static const darkSurface = Color(0xFF111318);
  static const darkSurfaceCard = Color(0xFF1A1D24);
  static const darkSurfaceElevated = Color(0xFF22262E);

  static const darkTextPrimary = Color(0xFFE2E8F0);
  static const darkTextSecondary = Color(0xFFA0AEC0);
  static const darkTextTertiary = Color(0xFF5A6577);

  static const darkDivider = Color(0xFF2D3340);
  static const darkError = Color(0xFFFC8181);
}

abstract final class AppTheme {
  static const _pretendard = 'Pretendard';

  // ── Light Theme ──
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
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

  // ── Dark Theme ──
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.darkError,
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        fontFamily: _pretendard,
        scaffoldBackgroundColor: AppColors.darkSurface,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.darkTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: _pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextPrimary,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurfaceCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkDivider,
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.accent,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(
            color: AppColors.darkTextTertiary,
            fontSize: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.darkSurface,
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
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.darkSurface,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkSurfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
      );

  // ── Cupertino ──
  static CupertinoThemeData get cupertinoLight => const CupertinoThemeData(
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.surface,
        barBackgroundColor: Color(0xF0F5F5F3),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primaryDark,
        ),
      );

  static CupertinoThemeData get cupertinoDark => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: AppColors.darkSurface,
        barBackgroundColor: Color(0xF0111318),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.accent,
        ),
      );
}
