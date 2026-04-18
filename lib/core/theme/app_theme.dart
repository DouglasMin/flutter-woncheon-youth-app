import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Serene (고요) palette — warm ivory + sage green.
/// All semantic tokens live here. Prefer reading via `context.wc` for
/// mode-aware access; static accessors below are kept for legacy call sites.
abstract final class AppColors {
  // ── Light (serene) ──
  static const bg = Color(0xFFF4F1EB);
  static const surface = Color(0xFFFBF8F2);
  static const surfaceAlt = Color(0xFFEDE7DC);
  static const border = Color(0xFFE2DACB);
  static const borderStrong = Color(0xFFCFC4AE);

  static const text = Color(0xFF1F1D18);
  static const textSec = Color(0xFF5C564B);
  static const textTer = Color(0xFF948B7B);

  static const accent = Color(0xFF7A8F6B);
  static const accentSoft = Color(0xFFE4EADA);
  static const accentInk = Color(0xFF3E4D35);

  static const anon = Color(0xFFE8E3D3);
  static const anonBorder = Color(0xFFD5CBAF);
  static const anonText = Color(0xFF6B6453);

  static const danger = Color(0xFFA64B3A);
  static const success = Color(0xFF6B8E5A);

  // ── Dark (serene) ──
  static const darkBg = Color(0xFF16140F);
  static const darkSurface = Color(0xFF1F1C16);
  static const darkSurfaceAlt = Color(0xFF27231B);
  static const darkBorder = Color(0xFF2E2A22);
  static const darkBorderStrong = Color(0xFF3C3629);

  static const darkText = Color(0xFFF2ECDD);
  static const darkTextSec = Color(0xFFB3AC9A);
  static const darkTextTer = Color(0xFF7A7262);

  static const darkAccent = Color(0xFFA3B888);
  static const darkAccentSoft = Color(0xFF2D3326);
  static const darkAccentInk = Color(0xFFD7E2BF);

  static const darkAnon = Color(0xFF231F17);
  static const darkAnonBorder = Color(0xFF39321F);
  static const darkAnonText = Color(0xFFA59A7F);

  static const darkDanger = Color(0xFFE08271);
  static const darkSuccess = Color(0xFF9FC087);

  // ── Legacy name aliases (keep old call sites compiling during migration) ──
  static const primary = accent;
  static const primaryLight = textSec;
  static const primaryDark = text;
  static const accentLight = accentSoft;
  static const surfaceCard = surface;
  static const textPrimary = text;
  static const textSecondary = textSec;
  static const textTertiary = textTer;
  static const textOnDark = darkText;
  static const textOnDarkSecondary = darkTextSec;
  static const divider = border;
  static const error = danger;
  static const darkOverlay = text;
  static const darkSurfaceCard = darkSurface;
  static const darkSurfaceElevated = darkSurfaceAlt;
  static const darkTextPrimary = darkText;
  static const darkTextSecondary = darkTextSec;
  static const darkTextTertiary = darkTextTer;
  static const darkDivider = darkBorder;
  static const darkError = darkDanger;
}

/// Mode-aware design tokens. Attach via ThemeData.extensions and read via
/// `context.wc` (see extension below).
@immutable
class WCTokens extends ThemeExtension<WCTokens> {
  const WCTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.textSec,
    required this.textTer,
    required this.accent,
    required this.accentSoft,
    required this.accentInk,
    required this.anon,
    required this.anonBorder,
    required this.anonText,
    required this.danger,
    required this.success,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color textSec;
  final Color textTer;
  final Color accent;
  final Color accentSoft;
  final Color accentInk;
  final Color anon;
  final Color anonBorder;
  final Color anonText;
  final Color danger;
  final Color success;

  static const light = WCTokens(
    bg: AppColors.bg,
    surface: AppColors.surface,
    surfaceAlt: AppColors.surfaceAlt,
    border: AppColors.border,
    borderStrong: AppColors.borderStrong,
    text: AppColors.text,
    textSec: AppColors.textSec,
    textTer: AppColors.textTer,
    accent: AppColors.accent,
    accentSoft: AppColors.accentSoft,
    accentInk: AppColors.accentInk,
    anon: AppColors.anon,
    anonBorder: AppColors.anonBorder,
    anonText: AppColors.anonText,
    danger: AppColors.danger,
    success: AppColors.success,
  );

  static const dark = WCTokens(
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    surfaceAlt: AppColors.darkSurfaceAlt,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    text: AppColors.darkText,
    textSec: AppColors.darkTextSec,
    textTer: AppColors.darkTextTer,
    accent: AppColors.darkAccent,
    accentSoft: AppColors.darkAccentSoft,
    accentInk: AppColors.darkAccentInk,
    anon: AppColors.darkAnon,
    anonBorder: AppColors.darkAnonBorder,
    anonText: AppColors.darkAnonText,
    danger: AppColors.darkDanger,
    success: AppColors.darkSuccess,
  );

  @override
  WCTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? borderStrong,
    Color? text,
    Color? textSec,
    Color? textTer,
    Color? accent,
    Color? accentSoft,
    Color? accentInk,
    Color? anon,
    Color? anonBorder,
    Color? anonText,
    Color? danger,
    Color? success,
  }) =>
      WCTokens(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        text: text ?? this.text,
        textSec: textSec ?? this.textSec,
        textTer: textTer ?? this.textTer,
        accent: accent ?? this.accent,
        accentSoft: accentSoft ?? this.accentSoft,
        accentInk: accentInk ?? this.accentInk,
        anon: anon ?? this.anon,
        anonBorder: anonBorder ?? this.anonBorder,
        anonText: anonText ?? this.anonText,
        danger: danger ?? this.danger,
        success: success ?? this.success,
      );

  @override
  WCTokens lerp(ThemeExtension<WCTokens>? other, double t) {
    if (other is! WCTokens) return this;
    return WCTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSec: Color.lerp(textSec, other.textSec, t)!,
      textTer: Color.lerp(textTer, other.textTer, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      anon: Color.lerp(anon, other.anon, t)!,
      anonBorder: Color.lerp(anonBorder, other.anonBorder, t)!,
      anonText: Color.lerp(anonText, other.anonText, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension WCThemeContext on BuildContext {
  WCTokens get wc =>
      Theme.of(this).extension<WCTokens>() ?? WCTokens.light;
}

abstract final class AppTheme {
  static const _pretendard = 'Pretendard';
  static const _serif = 'Noto Serif KR';

  static String get pretendard => _pretendard;
  static String get serif => _serif;

  // ── Light ──
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    primary: AppColors.text,
    onPrimary: AppColors.bg,
    secondary: AppColors.accent,
    onSecondary: AppColors.bg,
    error: AppColors.danger,
  );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightScheme,
        fontFamily: _pretendard,
        scaffoldBackgroundColor: AppColors.bg,
        extensions: const [WCTokens.light],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: _pretendard,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 0.5,
          space: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(
            color: AppColors.textTer,
            fontSize: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.text,
            foregroundColor: AppColors.bg,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: _pretendard,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.text,
          foregroundColor: AppColors.bg,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.text,
          contentTextStyle: const TextStyle(
            color: AppColors.bg,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.bg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );

  // ── Dark ──
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.darkAccent,
    brightness: Brightness.dark,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkText,
    primary: AppColors.darkText,
    onPrimary: AppColors.darkBg,
    secondary: AppColors.darkAccent,
    onSecondary: AppColors.darkBg,
    error: AppColors.darkDanger,
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkScheme,
        fontFamily: _pretendard,
        scaffoldBackgroundColor: AppColors.darkBg,
        extensions: const [WCTokens.dark],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: _pretendard,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 0.5,
          space: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.darkAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkDanger),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(
            color: AppColors.darkTextTer,
            fontSize: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.darkText,
            foregroundColor: AppColors.darkBg,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontFamily: _pretendard,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkText,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkSurfaceAlt,
          contentTextStyle: const TextStyle(
            color: AppColors.darkText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.darkBg,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.darkSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );

  // ── Cupertino ──
  static CupertinoThemeData get cupertinoLight => const CupertinoThemeData(
        primaryColor: AppColors.text,
        scaffoldBackgroundColor: AppColors.bg,
        barBackgroundColor: Color(0xF0F4F1EB),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.text,
        ),
      );

  static CupertinoThemeData get cupertinoDark => const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.darkAccent,
        scaffoldBackgroundColor: AppColors.darkBg,
        barBackgroundColor: Color(0xF016140F),
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.darkAccent,
        ),
      );
}
