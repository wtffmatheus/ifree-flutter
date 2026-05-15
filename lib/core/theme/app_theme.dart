import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ── Freelancer Light ──────────────────────────────────────────────────────
  static ThemeData get freelancerLight => _build(
    seed: AppColors.freelancerPrimary,
    brightness: Brightness.light,
    scaffold: AppColors.bgLight,
    card: AppColors.bgCardLight,
    surface: AppColors.bgCardLight,
  );

  // ── Freelancer Dark ───────────────────────────────────────────────────────
  static ThemeData get freelancerDark => _build(
    seed: AppColors.freelancerPrimary,
    brightness: Brightness.dark,
    scaffold: AppColors.bgDark,
    card: AppColors.bgCardDark,
    surface: AppColors.bgCardDark,
  );

  // ── Company Light ─────────────────────────────────────────────────────────
  static ThemeData get companyLight => _build(
    seed: AppColors.companyPrimary,
    brightness: Brightness.light,
    scaffold: AppColors.bgLight,
    card: AppColors.bgCardLight,
    surface: AppColors.bgCardLight,
  );

  // ── Company Dark ──────────────────────────────────────────────────────────
  static ThemeData get companyDark => _build(
    seed: AppColors.companyPrimary,
    brightness: Brightness.dark,
    scaffold: AppColors.bgDark,
    card: AppColors.bgCardDark,
    surface: AppColors.bgCardDark,
  );

  static ThemeData _build({
    required Color seed,
    required Brightness brightness,
    required Color scaffold,
    required Color card,
    required Color surface,
  }) {
    final isDark = brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final border =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
      onSurface: textPrimary,
    ).copyWith(
      primary: seed,
      onPrimary: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Poppins',

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: Border(
          bottom: BorderSide(color: border, width: 0.5),
        ),
      ),

      // ── Cards ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── NavigationBar ─────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xF013131A)
            : AppColors.bgCardLight.withOpacity(0.95),
        indicatorColor: seed.withOpacity(0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Poppins',
            color: selected ? seed : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? seed : textSecondary,
            size: 24,
          );
        }),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ── Inputs ────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? const Color(0x0AFFFFFF) : const Color(0x06000000),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: seed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle:
            TextStyle(color: textSecondary, fontFamily: 'Poppins'),
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.5),
          fontFamily: 'Poppins',
        ),
        prefixIconColor: textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          side: BorderSide(
            color: seed.withOpacity(0.4),
            width: 1.2,
          ),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),

      // ── Tabs ─────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: seed,
        unselectedLabelColor: textSecondary,
        indicatorColor: seed,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: border,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: seed.withOpacity(0.1),
        selectedColor: seed.withOpacity(0.2),
        labelStyle:
            TextStyle(color: seed, fontFamily: 'Poppins'),
        side: BorderSide(
          color: seed.withOpacity(0.25),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: isDark
            ? const Color(0xFF2A2A38)
            : const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
        contentTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme:
          DividerThemeData(color: border, thickness: 0.5),

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          color: textPrimary,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          color: textPrimary,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          color: textSecondary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          color: textSecondary,
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textPrimary,
        ),
      ),
    );
  }
}