import 'package:flutter/material.dart';

/// Design tokens — single source for color, type, spacing.
/// calm teal (trust/service) + amber (priority/urgency).
class AppTokens {
  static const seed = Color(0xFF0E7C7B);
  static const urgent = Color(0xFFC2410C);
  static const success = Color(0xFF15803D);
  static const pending = Color(0xFFB45309);

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const minTarget = 48.0;
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppTokens.seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, AppTokens.minTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceSm,
        ),
      ),
    );
  }
}
