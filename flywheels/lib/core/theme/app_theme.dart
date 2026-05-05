import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppPalette {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const red = Color(0xFFFF0000);
  static const soft = Color(0xFFF5F5F5);
  static const border = Color(0xFFE5E5E5);
  static const muted = Color(0xFF666666);
}

abstract final class AppTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.white,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.red,
        onPrimary: AppPalette.white,
        secondary: AppPalette.black,
        surface: AppPalette.white,
        onSurface: AppPalette.black,
      ),
      textTheme: textTheme.copyWith(
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.black,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppPalette.black,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppPalette.black,
          height: 1.4,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppPalette.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.white,
        foregroundColor: AppPalette.black,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppPalette.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppPalette.border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.soft,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppPalette.red, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.red,
          foregroundColor: AppPalette.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.black,
          side: const BorderSide(color: AppPalette.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.soft,
        selectedColor: AppPalette.red.withValues(alpha: 0.1),
        labelStyle: const TextStyle(color: AppPalette.black),
        side: const BorderSide(color: AppPalette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppPalette.white : AppPalette.black,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppPalette.black : AppPalette.white,
          ),
          side: WidgetStateProperty.all(const BorderSide(color: AppPalette.border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppPalette.black,
        textColor: AppPalette.black,
      ),
      dividerColor: AppPalette.border,
    );
  }
}
