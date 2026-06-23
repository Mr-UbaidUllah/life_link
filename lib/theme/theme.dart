import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — single source of truth for color.
///
/// Direction: "refined blood red" — crimson signals the domain (blood) while a
/// proper tonal ramp + semantic colors keep it trustworthy and accessible.
class AppColors {
  AppColors._();

  // ---- Brand (crimson) ----
  static const Color primary = Color(0xFFD7263D);
  static const Color primaryDeep = Color(0xFF9D1C2E); // hero/gradients
  static const Color primaryBright = Color(0xFFFF5A6E); // primary on dark
  static const Color primarySoft = Color(0xFFFCE7EA); // tinted fills (light)

  // ---- Semantic ----
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A13A);
  static const Color info = Color(0xFF2D6CDF);
  static const Color danger = Color(0xFFD7263D);

  // ---- Vibrant accents (bold-modern gradients, energy CTAs) ----
  static const Color coral = Color(0xFFFF4D6D); // crimson → coral ramp
  static const Color magenta = Color(0xFFB5179E); // hero gradient tail
  static const Color violet = Color(0xFF7209B7); // deep vibrant accent

  // ---- Accents (blood-group chips, impact tiles) ----
  static const Color teal = Color(0xFF2A9D8F);
  static const Color blue = Color(0xFF2D6CDF);
  static const Color amber = Color(0xFFE8A13A);
  static const Color green = Color(0xFF2E9E5B);
  static const Color plum = Color(0xFF6D597A);
  static const Color indigo = Color(0xFF52489C);

  // ---- Light neutrals ----
  static const Color lightBackground = Color(0xFFF6F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF0F1F4);
  static const Color lightText = Color(0xFF14171F);
  static const Color lightMuted = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE6E8EC);

  // ---- Dark neutrals ----
  static const Color darkBackground = Color(0xFF0E0F13);
  static const Color darkSurface = Color(0xFF181A20);
  static const Color darkSurfaceAlt = Color(0xFF21242C);
  static const Color darkText = Color(0xFFEAECEF);
  static const Color darkMuted = Color(0xFF9AA0AA);
  static const Color darkBorder = Color(0xFF2A2D36);
}

/// Vibrant gradients — the "bold & vibrant" signature.
/// Use for hero surfaces, primary CTAs and urgency emphasis.
class AppGradients {
  AppGradients._();

  /// Signature brand sweep: crimson → coral → magenta.
  static const LinearGradient hero = LinearGradient(
    colors: [AppColors.primary, AppColors.coral, AppColors.magenta],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Tighter, hotter sweep for critical / urgent emphasis.
  static const LinearGradient urgent = LinearGradient(
    colors: [AppColors.primaryDeep, AppColors.primary, AppColors.coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Calm positive state (eligible, available, success).
  static const LinearGradient success = LinearGradient(
    colors: [AppColors.green, AppColors.teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cool informational sweep (impact, trust).
  static const LinearGradient info = LinearGradient(
    colors: [AppColors.indigo, AppColors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft glow shadow tuned to a brand color (for elevated CTAs).
  static List<BoxShadow> glow(Color color, {double alpha = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}

/// Motion tokens — consistent timing & easing across the redesigned app.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration count = Duration(milliseconds: 900);

  /// Default entrance/standard easing (decelerate).
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasized, slightly springy easing for hero/CTA motion.
  static const Curve emphasized = Curves.easeOutBack;

  /// Stagger step between sequential list-item entrances.
  static const Duration stagger = Duration(milliseconds: 70);
}

/// Spacing scale (logical px before screenutil). Use multiples of 4.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Corner-radius scale — bold-modern leans large.
class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class AppTheme {
  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final primary = isDark ? AppColors.primaryBright : AppColors.primary;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final onSurface = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.info,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceAlt,
      error: AppColors.danger,
      outline: border,
    );

    // Figtree — clean, modern, accessible; one family across the hierarchy.
    final baseText =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.figtreeTextTheme(baseText)
        .apply(bodyColor: onSurface, displayColor: onSurface)
        .copyWith(
          displaySmall: GoogleFonts.figtree(
              fontWeight: FontWeight.w800, letterSpacing: -0.5, color: onSurface),
          headlineMedium: GoogleFonts.figtree(
              fontWeight: FontWeight.w800, letterSpacing: -0.4, color: onSurface),
          headlineSmall: GoogleFonts.figtree(
              fontWeight: FontWeight.w800, letterSpacing: -0.3, color: onSurface),
          titleLarge: GoogleFonts.figtree(
              fontWeight: FontWeight.w800, letterSpacing: -0.2, color: onSurface),
          titleMedium: GoogleFonts.figtree(
              fontWeight: FontWeight.w700, color: onSurface),
          titleSmall: GoogleFonts.figtree(
              fontWeight: FontWeight.w700, color: onSurface),
          labelLarge: GoogleFonts.figtree(fontWeight: FontWeight.w700),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          textStyle: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: border, width: 1.5),
          textStyle: GoogleFonts.figtree(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.figtree(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: primary,
        side: BorderSide(color: border),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: onSurface),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
    );
  }
}
