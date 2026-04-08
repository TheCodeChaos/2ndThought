import 'package:flutter/material.dart';
import 'color_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: kBackground,
      primaryColor: kAccentCyan,
      colorScheme: const ColorScheme.dark(
        primary: kAccentCyan,
        secondary: kAccentAmber,
        surface: kSurface,
        error: kAccentRed,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: kTextPrimary,
        onError: Colors.white,
      ),
      fontFamily: 'SpaceMono',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'FiraCode',
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'FiraCode',
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'FiraCode',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
        titleSmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: kTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 16,
          color: kTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 14,
          color: kTextPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 12,
          color: kTextSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: kTextSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: kSurfaceAlt,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentCyan,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kAccentCyan,
          side: const BorderSide(color: kAccentCyan, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        iconTheme: IconThemeData(color: kTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kSurface,
        selectedItemColor: kAccentCyan,
        unselectedItemColor: kTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 11,
        ),
      ),
      dividerColor: kDivider,
      dividerTheme: const DividerThemeData(
        color: kDivider,
        thickness: 1,
        space: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kSurfaceAlt,
        contentTextStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          color: kTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: kAccentCyan,
        inactiveTrackColor: kDivider,
        thumbColor: kAccentCyan,
        overlayColor: kAccentCyanDim,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccentCyan;
          return kTextSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return kAccentCyanDim;
          return kDivider;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kSurfaceAlt,
        selectedColor: kAccentCyanDim,
        labelStyle: const TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 12,
          color: kTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: const BorderSide(color: kDivider),
      ),
    );
  }
}
