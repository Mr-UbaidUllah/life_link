import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — the single source of truth for colors so every screen
/// pulls from the same set instead of ad-hoc Colors.x.shadeY values.
class AppColors {
  AppColors._();

  /// Imperial red — warm and urgent without being alarming.
  static const Color primary = Color(0xFFE63946);

  /// Lighter primary used on dark surfaces for contrast.
  static const Color primaryBright = Color(0xFFFF6B7A);

  /// Deep red used for gradients (splash, hero banners).
  static const Color primaryDeep = Color(0xFF9B1C26);

  // Supporting accents — muted, equal-weight tones that don't fight
  // the primary red for attention.
  static const Color teal = Color(0xFF2A9D8F);
  static const Color blue = Color(0xFF3A7CA5);
  static const Color amber = Color(0xFFEE9B00);
  static const Color green = Color(0xFF4C9F70);
  static const Color plum = Color(0xFF6D597A);
  static const Color indigo = Color(0xFF52489C);

  // Semantic colors — use these instead of raw Colors.green/orange/blue so
  // meaning (success/warning/info/error) is consistent and dark-mode safe.
  static const Color success = green;
  static const Color warning = amber;
  static const Color info = blue;
  static const Color danger = Color(0xFFD62828);

  // Light mode
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1C1F26);

  // Dark mode
  static const Color darkBackground = Color(0xFF101216);
  static const Color darkSurface = Color(0xFF191C22);
  static const Color darkText = Color(0xFFEAECEF);
}

class AppTheme {
  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryBright : AppColors.primary;
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final onSurface = isDark ? AppColors.darkText : AppColors.lightText;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: primary,
      surface: surface,
      onSurface: onSurface,
    );

    final baseText = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseText).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: onSurface.withValues(alpha: 0.06)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerColor: onSurface.withValues(alpha: 0.08),
    );
  }
}
